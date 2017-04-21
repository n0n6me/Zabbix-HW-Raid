#!/usr/bin/env perl
use Data::Dumper qw(Dumper);

($device, $metric, $raw) = @ARGV;
$device = lc $device;
$metric = lc $metric;
$metric =~ s/_/ /g;

sub ad_ld {
	$arg = @_[0];
	#print "~~~ " . $arg." ~~~\n";
	open(FILE,"/tmp/accraid_" . $arg) || die 'Cant open';
	while (<FILE>) {
		@line = split(':', $_);
    	@line[0] =~ s/^\s+|\s+$//g;
    	@line[0] =~ s/\n//g;
		@line[0] = lc @line[0];
    	@line[1] =~ s/^\s+|\s+$//g;
    	@line[1] =~ s/\n//g;
		@linr[1] = lc @line[1];
    	$hash{@line[0]} = @line[1];
    }
    return %hash;
}

sub pd_all {
	#print "~~~ pd ~~~\n";
	open(FILE,"/tmp/accraid_pd" ) || die 'Cant open';
	@file = 'start';
	while (<FILE>) {
		$count++;
		$_ =~ s/^\s+|\s+$//g;
		$_ =~ s/\h+/ /g;
		@file = (@file,$_);
		if ( $_  =~ /^Device #/){
			  #  позиция файле откуда начинается следующий диск
              #print "~~~~~~~count: ".$count." ~~~~~~~~~\n";
              @chank = (@chank,$count);
		}
		for $index (0..$#chank){
			#print $index." ".$chank[$index]."\n";
        	@file[$chank[$index]] = lc @file[$chank[$index]];
			$dev{@file[$chank[$index]]}{'self'} = 	@file[$chank[$index]];
			#print "chank[index] : ". $chank[$index] . " " . $chank[$index+1]."\n";
			$start =  $chank[$index]; $stop = ($chank[$index+1]-1);
			#print "start stop :" .$start.  " " . $stop."\n";
			for $i ($start..$stop){
				#print $i . " => ";
				#print @file[$i]."\n";
				@f = split (':',@file[$i]);
				@f[0] =~ s/^\s+|\s+$//g;
				@f[0] = lc @f[0];
				@f[1] =~ s/^\s+|\s+$//g;
				@f[1] = lc @f[1];
				$dev{@file[$chank[$index]]}{@f[0]} = @f[1];
			}
	    	$i = 0;
		}
	}
	#print Dumper \%dev;
	return %dev;
}


sub pd {
	$device = @_[0];
	$device =~ s/_/ #/g;
	open(FILE,"/tmp/accraid_pd" ) || die 'Cant open';
	@file = 'start';
	while (<FILE>) {
		$count++;
		$_ =~ s/^\s+|\s+$//g;
		$_ =~ s/\h+/ /g;
		@file = (@file,$_);
		if ( (lc $_)  =~ /^$device/){
              @chank = (@chank,$count);
		}
		if ( (lc $_)  =~ /^device #/ && $#chank == 0 && $count > @chank[0]){
			$dev{lc @file[$chank[$index]]}{'self'} = lc @file[$chank[$index]];
			$start = @chank[0]; $stop = $count - 1;
			for $i ($start .. $stop){
				@f = split (':',@file[$i]);
				@f[0] =~ s/^\s+|\s+$//g;
				@f[0] = lc @f[0];
				@f[1] =~ s/^\s+|\s+$//g;
				@f[1] = lc @f[1];
				$dev{lc @file[$chank[$index]]}{@f[0]} = @f[1];
			}
			#print Dumper \%dev;
			return %dev;
		}
	}
}

sub collect {
	for $i ('ad','ld','pd'){
		$status = system("sudo /usr/sbin/arcconf GETCONFIG 1 $i > /tmp/accraid_$i");
		if ($status != 0){
			print "1\n";
			exit;
		}
	}
	print "0\n";
}

sub discovery {
	%pd = pd_all();
	print "{\n\"data\": [";
	$count = 0;
	 while ( my ($key, $value) = each(%pd) ) {
	 	        $key =~ s/ #/_/g;
	 	        if ($count != 0){
		    		print 	",\n{\"{#HARDDISK}\":\"" .  $key . "\"}";
		    	} else {
		    		print 	"\n{\"{#HARDDISK}\":\"" .  $key . "\"}";
		    	}
		    	$count++;
    }
    print "\n]\n}\n";
}

sub status {
	$arg = lc @_[0];
    %status = (
  		'online' 	=> 0
		,'optimal'	=> 0
  		,'zmm optimal' 	=> 0
  		,'on' 		=> 0
  		,'normal' 	=> 0
  		,'enabled' 	=> 0
  		,'enabled (write-back)' => 0
  		,'rebuilding' => 3
  		,'global hot-spare' => 2
    	);

    if (length($status{$arg}) < 1 ) {
    	return 1;
    }
    else {
    	return $status{$arg};
    }
}


if ($metric =~ /^collect/) {
	collect();
}

if ($metric =~ /^discovery/) {
	discovery();
}
if ($device =~ /^device_/) {
	%pd = pd($device);
	if ($raw){
		print $pd{$device}{$metric}."\n";
	}
	else {
		print status($pd{$device}{$metric})."\n";
	}
}

if ($device =~ /ld/) {
	%data = ad_ld('ld');
	if ($raw){
	 	print $data{$metric}."\n";
	}
	else {
	 	print status($data{$metric})."\n";
	}
}

if ($device =~ /ad/) {
	%data = ad_ld('ad');
	if ($raw){
	 	print $data{$metric}."\n";
	}
	else {
	 	print status($data{$metric})."\n";
	}
}


