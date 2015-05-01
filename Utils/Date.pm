package PGL::Utils::Date;

=head1 NAME
 
  PGL::Utils::Date - An encapsulation of common GPS date calculations
 
=head1 SYNOPSIS
 
    use PGL::Utils::DATE;
    
    my $date;
    
    # all equivalent
    $date = new Date(mjd => 52945);
    $date = new Date(fyear => 2003.8369);
    $date = new Date(Year => 2003, doy => 306);
    $date = new Date(gpsWeek => 1243, gpsWeekDay => 0);
    $date = new Date(day => 2, month => 11, year => 2003);
    
    # regardless of initialization input all fields are computed
    print "day: "       , $date -> day       , "\n";
    print "doy: "       , $date -> doy       , "\n";
    print "mjd: "       , $date -> mjd       , "\n";
    print "year: "      , $date -> year      , "\n";
    print "fyear: "     , $date -> fyear     , "\n";
    print "month: "     , $date -> month     , "\n";
    print "gpsWeek: "   , $date -> gpsWeek   , "\n";
    print "gpsWeekDay: ", $date -> gpsWeekDay, "\n";
    
    # all arithmetic operators have been overloaded 
    my $startDate = new Date(gpsWeek => 1094, gpsWeekDay => 3);
    for (my $i = $startDate; $i <= $startDate+7; $i++){
        print $i,"\n";
    }
 
=head1 DESCRIPTION
 
  This date object allows for encapsulation of date information
  used for a typical GPS type perl code.  These Date objects
  can be initialized using any of the common inputs such as 
  year and day of year, gpsWeek and gpsWeekDay, and so on.
 
  Regardless of the initialization input all other fields will be 
  automatically computed. This makes date conversions simple.  
  Although, through proper use of this object the user should
  let go of the "date conversion" mind set and just trade 
  date objects around.  For example the input to a function could 
  be a date object and the user need not care which date specific 
  peices of date information any function needs.  Functions 
  get a date object and can get pull out what they need themselves.  
 
=head2 Functions

  All date information is computed regardless of initialization
  Therefore, there are no functions for "date conversions".
  Just access what you need.  
  
  The exception is the habitual need for a standardized 3-char 
  day of year string.  This is the only function provided 
  for public consumption.
  
=head3 doyStr
 
      $date -> doyStr();
 
  Returns a three character string DDD.
  For example doy 1 -> "001", doy 46 -> "046", and doy 281 -> "281"
  
=head1 AUTHOR

    Abel Brown (brown.2179@gmail.com)
        
=head1 SEE ALSO
 
=cut

use Carp;
use POSIX;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

use overload ('<=>' => \&spaceship,
               '+'  => \&add,
               '-'  => \&subtract,
               '""' => \&stringify,
               '0+' => \&numify);

# accessors
sub year       { return shift -> {_year}       }
sub doy        { return shift -> {_doy}        }
sub day        { return shift -> {_day}        }
sub month      { return shift -> {_month}      }
sub gpsWeek    { return shift -> {_gpsWeek}    }
sub gpsWeekDay { return shift -> {_gpsWeekDay} }
sub fyear      { return shift -> {_fyear}      }
sub mjd        { return shift -> {_mjd}        }

sub new {
	
	# get the class name
	my $class = shift;
	
	# get the input keyword args
	my (%kwargs) = @_;
	
	# initialize self hash
	my $self = { 
		_year       => undef,
		_doy        => undef,
		_day        => undef,
		_month      => undef,
		_fyear      => undef,
		_gpsWeek    => undef,
		_gpsWeekDay => undef,
		_mjd        => undef
	};
	
	while ( my ($key, $value) =  each(%kwargs) ) {
		
		# make sure the key is lower case
		$key = lc($key);
		
		# make sure the value is numeric
		if ( ! looks_like_number($value) ){
			confess("Could not parse value for key: $key, $value is not numeric\n")
		}
		
		# parse kwargs
		if ( $key =~ /^year$/ ){

			if ( $value < 0 ){
				confess("Input year: $value is invalid.  Year must be positive\n")
			}
			
			# assign the year to the object
			$self->{_year} = int($value);
			
		} elsif ( $key =~ /^doy$/) {

			# confirm validity
			if ( $value < 0 || $value > 366 ){
				confess("Input doy: $value is invalid.  Day of year must be between 1 and 366\n");
			}
			
			# assign day of year
			$self->{_doy} = int($value)
		
		} elsif ( $key =~ /^day$/) {

			# confirm validity
			if ( $value < 0 || $value > 31 ){
				confess("Input day: $value is invalid.  Day of month must be between 1 and 31\n");
			}
			
			# assign day of month
			$self->{_day} = int($value);
			 
		} elsif ( $key =~ /^month$/) {
			
			# confirm validity
			if ( $value < 0 || $value > 12 ){
				confess("Input month: $value is invalid.  Month must be between 1 and 12\n");
			}
			
			# assign month
			$self->{_month} = int($value);
		
		} elsif ( $key =~ /^gpsweek$/) {

			# confirm validity
			if ( $value < 0 ){
				confess("Input gpsWeek: $value is invalid.  GPS week must be positive\n");
			}
			
			# assign gps week
			$self->{_gpsWeek} = int($value);
			
		} elsif ( $key =~ /^gpsweekday$/) {

			# confirm validity
			if ( $value < 0 || $value > 6 ){
				confess("Input gpsWeekDay: $value is invalid.  gpsWeekDay must be between 0 and 6\n");
			}
			
			# assign day of gpsWeek
			$self->{_gpsWeekDay} = int($value);
			
		} elsif ( $key =~ /^fyear$/) {
			
			# confirm validity
			if ( $value < 0 ){
				confess("Input fractional year: $value is invalid.  Fractional year must be positive\n");
			}
			
			# assign fractional year
			$self->{_fyear} = $value;
			
		} elsif ( $key =~ /^mjd$/) {
			
			# confirm validity
			if ( $value < 0 ){
				confess("Modified julian day value: $value is invalid.  MJD must be positive\n");
			}
			
			# assign modified julian day
			$self->{_mjd} = int($value);
			
		} else {
		 
		 # no clue what this is so yell at the user 
		 carp("Unrecognized input key: $key, with value: $value\n");
		}
	}
	
	# OK, now figure out what we gots
	if ( defined($self->{_year}) && defined($self->{_doy}) ){
	 	 
		# compute the fractional year
		$self->{_fyear} = __yeardoy2fyear(year=>$self->{_year}, doy =>$self->{_doy});
		
		# compute the month and day of month
		( $self->{_month}, $self->{_day} ) = __doy2date(year=>$self->{_year}, doy=>$self->{_doy});
		
		# compute the gps date information week and day of week
		($self->{_gpsWeek},$self->{_gpsWeekDay}) = __date2gpsDate(year=>$self->{_year}, month=>$self->{_month}, day=>$self->{_day});
		
		# compute the modified julian day
		$self->{_mjd} = __gpsDate2mjd(gpsWeek=>$self->{_gpsWeek}, gpsWeekDay=>$self->{_gpsWeekDay});
	
		 
	}elsif ( defined( $self->{_fyear} ) ){

        # compute year and day of year from fractional year
	    ( $self->{_year}, $self->{_doy} )  = __fyear2yeardoy(fyear=>$self->{_fyear});
	    
	    # compute the month and day from year and day of year
	    ( $self->{_month}, $self->{_day} ) = __doy2date(year=>$self->{_year}, doy=>$self->{_doy});
	    
	    # compute gps week and gps day of week from year month and day
	    ($self->{_gpsWeek},$self->{_gpsWeekDay}) = __date2gpsDate(year=>$self->{_year}, month=>$self->{_month}, day=>$self->{_day});
	    
	    # compute the modified julian day
		$self->{_mjd} = __gpsDate2mjd(gpsWeek=>$self->{_gpsWeek}, gpsWeekDay=>$self->{_gpsWeekDay});
	    
	     
	} elsif ( defined($self->{_year}) && defined($self->{_month}) && defined($self->{_day}) ){
	    
	    # compute year and day of year from fractional year
	    $self->{_doy} = __date2doy(year=>$self->{_year}, month=>$self->{_month}, day=>$self->{_day});
	    
	    # compute the fractional year from year and day of year
		$self->{_fyear} = __yeardoy2fyear(year=>$self->{_year}, doy =>$self->{_doy});
		
		($self->{_gpsWeek},$self->{_gpsWeekDay}) = __date2gpsDate(year=>$self->{_year}, month=>$self->{_month}, day=>$self->{_day});
		
		# finally compute the modified julian day
		$self->{_mjd} = __gpsDate2mjd(gpsWeek=>$self->{_gpsWeek}, gpsWeekDay=>$self->{_gpsWeekDay});
		
		
	} elsif ( defined($self->{_gpsWeek})  && defined($self->{_gpsWeekDay}) ){
	    
	    # compute the modified julian day
		$self->{_mjd} = __gpsDate2mjd(gpsWeek=>$self->{_gpsWeek}, gpsWeekDay=>$self->{_gpsWeekDay});
	    
	    # compute the year month and day from modified julian day 
	    ( $self->{_year}, $self->{_month}, $self->{_day} ) = __mjd2date(mjd=>$self->{_mjd});
	    
	    # compute the day of year from year, month, and day
	    $self->{_doy} = __date2doy(year=>$self->{_year}, month=>$self->{_month}, day=>$self->{_day});
	    
	    # compute the fractional year from year and day of year
		$self->{_fyear} = __yeardoy2fyear(year=>$self->{_year}, doy =>$self->{_doy});
	    
	} elsif ( defined($self->{_mjd}) ){
	    
	    # compute the year month and day from modified julian day 
	    ( $self->{_year}, $self->{_month}, $self->{_day} ) = __mjd2date(mjd=>$self->{_mjd});

	    # compute the day of year from year, month, and day
	    $self->{_doy} = __date2doy(year=>$self->{_year}, month=>$self->{_month}, day=>$self->{_day});
	    	    
	    # compute the fractional year from year and day of year
		$self->{_fyear} = __yeardoy2fyear(year=>$self->{_year}, doy =>$self->{_doy});
		
		# compute the gps date informations from year, month and day of month
		($self->{_gpsWeek},$self->{_gpsWeekDay}) = __date2gpsDate(year=>$self->{_year}, month=>$self->{_month}, day=>$self->{_day});
		
		
	} else {
	    confess("Not enough independant input args to compute full date.  Consult documentation for valid inputs.\n");
	}
	
	return bless($self,$class);
}

sub __yeardoy2fyear { 
	
	# get the input keyword args
	my (%kwargs) = @_;
	
	# initialize year an doy to null
	my $year = undef;
	my $doy  = undef; 
	my $hour = 12;
    
    # parse input args in any order
    while ( my ($key,$value) = each(%kwargs) ){
        $key = lc($key);
        if (! looks_like_number($value)){confess "input key: $key, value: $value must be integers\n"}
        if ($key =~ /^year$/)   { $year = $value }
        elsif ($key =~ /^doy$/) { $doy  = $value }
        else{confess("Unrecognized key: $key, with value $value\n")}        
    }
    
    # make sure we have year and doy defined to proceed
    if (! defined($year) || ! defined($doy) ){
        confess("YYYY and DDD are required input\n")
    }
    
    # default number of days in a year
    my $diy=365;
    
    # check for leap years
    if ($year % 4 == 0){ $diy = $diy + 1; }
    
    # compute the fractional year
    my $fractionalYear = $year + (($doy-1)+$hour/24.0)/$diy;
    
    # that's all ...
    return $fractionalYear;
}

sub __fyear2yeardoy{
 
    # get the input keyword args
	my (%kwargs) = @_;
	
	# init
	my $year  = undef;
	my $doy   = undef;
	my $fyear = undef;
	
	# parse those input args
	while (my ($key,$value) = each(%kwargs)) {
	 
	    # convert to lower case 
	    $key = lc($key);
	    
	    # make sure value is  actually a number
        if (! looks_like_number($value)){confess "input key: $key, value: $value must be integers\n"}
        
        # look for fyear input
        if ($key =~ /^fyear$/){ $fyear = $value; }
        
        # otherwise bulk at the user
        else{ confess("Unrecognized key: $key with value: $value"); }
	}
	
	# make sure we have at least fyear from the input
	if ( ! defined($fyear) ){ confess("fyear is required input\n"); }
        
    # figure out the year
    $year = floor($fyear);
        
    # figure out the fractional part of the year
    my $fractionOfyear = $fyear - $year;
        
    # compute the day of year
    $doy = floor( 365 * $fractionOfyear ) + 1;
    
    # recompute day of year if is a leap year
    if ($year % 4 == 0){
        $doy = floor ( 366 * $fractionOfyear ) + 1;
    }
     
    return (int($year),int($doy)); 
}

sub __date2doy{
    
    # get the input keyword args
	my (%kwargs) = @_;
	
	# init
    my $year  = undef;
    my $month = undef;
    my $day   = undef;
    my $doy   = undef;
    my $hour  = 12;
    my @lday  = ();
	
	# parse those input args
	while (my ($key,$value) = each(%kwargs)) {
	 
	    # convert to lower case 
	    $key = lc($key);
	    
	    # make sure value is  actually a number
        if (! looks_like_number($value)){confess "input key: $key, value: $value must be integers\n"}
        
        # look for year input
        if ($key =~ /^year$/){ $year = $value; }
        
        # look for day of month input
        elsif ($key =~ /^day$/){ $day = $value; }
        
        # look for month input
        elsif ($key =~ /^month$/){ $month = $value; }
        
        # otherwise bulk at the user
        else{ confess("Unrecognized key: $key with value: $value"); }
	}
	
	# make sure we have required inputs at this point
	if ( ! defined($year) || ! defined($month) || ! defined($day) ){
	    confess("year month day  are required key-word input args");
	}

    # localized days of year
    if ( $year % 4 == 0){
        @lday = (0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366);
    } else {
        @lday =  (0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365); 
    }
    
    # compute the day of year
    $doy = $lday[ $month-1 ] + $day;
        
    # that's a [w]rap
    return $doy;
}

sub __doy2date{
    
    # get the input keyword args
	my (%kwargs) = @_;

    # init
    my $year  = undef;
    my $doy   = undef;
    my $month = undef;
    my $day   = undef;
    my @lday  = ();
    my @fday  = ();

    # parse those input args
	while (my ($key,$value) = each(%kwargs)) {
	 
	    # convert to lower case 
	    $key = lc($key);
	    
	    # make sure value is  actually a number
        if (! looks_like_number($value)){confess "input key: $key, value: $value must be integers\n"}
        
        # look for year input
        if ($key =~ /^year$/){ $year = $value; }
        
        # look for day of month input
        elsif ($key =~ /^doy$/){ $doy = $value; }
        
        # otherwise bulk at the user
        else{ confess("Unrecognized key: $key with value: $value"); }
	}
	
	# make sure we have required inputs at this point
	if ( ! defined($year) || ! defined($doy) ){
	    confess("year and doy are required key-word input args");
	}

    # make note of leap year or not
    my $isLeapYear=0;
    if ($year % 4 == 0){ $isLeapYear = 1 }; 
    
    # make note of valid doy for year
    my $mxd = 365;
    if ($isLeapYear){ $mxd = $mxd + 1 };
        
    # check doy based on year
    if ($doy < 1 or $doy > $mxd){
        confess("day of year: $doy is invalid for year: $year\n");
    }
    # localized days
    if (! $isLeapYear){
        @fday = (1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335);
        @lday = (31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365);
    }else{
        @fday = (1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336);
        @lday = (31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366);
    }
    # compute the month
    for (my $i = 0; $i < 12; $i++){
        if ($doy <= $lday[$i]){ $month=$i+1; last;}
    }
        
    # compute the day (dont forget zero based indexing)
    $day = $doy - $fday[ $month-1 ] + 1;
    
    return ($month,$day);
    
}

sub __date2gpsDate{
    
    # get the input keyword args
	my (%kwargs) = @_;
    
    # init
    my $year       = undef;
    my $month      = undef;
    my $day        = undef;
    my $ut         = undef;
    my $gpsWeek    = undef;
    my $gpsWeekDay = undef;
    
    # parse those input args
	while (my ($key,$value) = each(%kwargs)) {
	 
	    # convert to lower case 
	    $key = lc($key);
	    
	    # make sure value is  actually a number
        if (! looks_like_number($value)){confess "input key: $key, value: $value must be integers\n"}
        
        # look for year input
        if ($key =~ /^year$/){ $year = $value; }
        
        # look for day of month input
        elsif ($key =~ /^day$/){ $day = $value; }
        
        # look for month input
        elsif ($key =~ /^month$/){ $month = $value; }
        
        # otherwise bulk at the user
        else{ confess("Unrecognized key: $key with value: $value"); }
	}
	
	# make sure we have required inputs at this point
	if ( ! defined($year) || ! defined($month) || ! defined($day) ){
	    confess("year month day  are required key-word input args");
	}
    
    if ($month <= 2){
        $month += 12;
        $year  -=  1;
    }
        
    $ut  = ($day % 1) *24.0;
    $day = floor($day); 
    
    my $julianDay = floor( 365.25 * $year )              
                  + floor( 30.6001 * ( $month + 1.0 ) )   
                  + $day                                      
                  + $ut/24.0                                   
                  + 1720981.5;
                
    # do it!
    $gpsWeek    = floor(($julianDay - 2444244.5)/7.0);
    $gpsWeekDay = ($julianDay - 2444244.5) % 7;
    
    # that's a [w]rap
    return (int($gpsWeek), int($gpsWeekDay));
    
}

sub __gpsDate2mjd{
    
    # get the input keyword args
	my (%kwargs) = @_;
    
    # parse to integers
    my $gpsWeek    = undef;
    my $gpsWeekDay = undef;
    my $mjd        = undef;
    
    # parse those input args
	while (my ($key,$value) = each(%kwargs)) {
	 
	    # convert to lower case 
	    $key = lc($key);
	    
	    # make sure value is  actually a number
        if (! looks_like_number($value)){confess "input key: $key, value: $value must be integers\n"}
        
        # look for gps week input
        if ($key =~ /^gpsweek$/){ $gpsWeek = $value; }
        
        # look for day of gps week input
        elsif ($key =~ /^gpsweekday$/){ $gpsWeekDay = $value; }
        
        # otherwise bulk at the user
        else{ confess("Unrecognized key: $key with value: $value"); }
	}
	
	# make sure we have required inputs at this point
	if ( ! defined($gpsWeek) || ! defined($gpsWeekDay) ){
	    print $gpsWeek," ",$gpsWeekDay,"\n";
	    confess("gpsWeek and gpsWeekDay are required key-word input args\n");
	}
    
    # simple
    $mjd = ($gpsWeek * 7.0) + 44244.0 + $gpsWeekDay;
    
    return int($mjd);
}

sub __mjd2date{
    
    # get the input keyword args
	my (%kwargs) = @_;
    
    my $a = undef;
    my $b = undef;
    my $c = undef;
    my $d = undef;
    my $e = undef;
    my $m = undef;
    
    my $year  = undef;
    my $month = undef;
    my $day   = undef;
    
    my $jd    = undef;
    my $ijd   = undef;
    my $mjd   = undef;
    
    # parse those input args
	while (my ($key,$value) = each(%kwargs)) {
	 
	    # convert to lower case 
	    $key = lc($key);
	    
	    # make sure value is  actually a number
        if (! looks_like_number($value)){confess "input key: $key, value: $value must be integers\n"}
        
        # look for fyear input
        if ($key =~ /^mjd/){ $mjd = $value; }
        
        # otherwise bulk at the user
        else{ confess("Unrecognized key: $key with value: $value"); }
	}
	
	# make sure we have at least fyear from the input
	if ( ! defined($mjd) ){ confess("mjd is required key-word input arg\n"); }
    
    $mjd = $mjd+0.0;
    
    $jd = $mjd + 2400000.5;
    
    $ijd = floor($jd + 0.5);
    
    $a = $ijd + 32044.0;
    $b = floor((4.0 * $a + 3.0) / 146097.0);
    $c = $a - floor(($b * 146097.0) / 4.0);
    
    $d = floor((4.0 * $c + 3.0) / 1461.0);
    $e = $c - floor((1461.0 * $d) / 4.0);
    $m = floor((5.0 * $e + 2.0) / 153.0);
    
    $day   = $e - floor((153.0 * $m + 2.0) / 5.0) + 1.0;
    $month = $m + 3.0 - 12.0 * floor($m / 10.0);
    $year  = $b * 100.0 + $d - 4800.0 + floor($m / 10.0);

    # that's all folks
    return (int($year),int($month),int($day));   
}

sub doyStr{
    
    # get reference to obj
    my $self = shift;
    
    # easier to write 
    my $doy = $self->{_doy};
    
    # format as 3-digit string
    if ($doy < 10){
        return "00".$doy;     
    }elsif ($doy >= 10 && $doy < 100){
        return "0".$doy;
    }else{
        return "".$doy;
    }
}

sub spaceship{
    my ($d1,$d2,$inverted)= @_;
    return $d1->{_mjd} cmp $d2->{_mjd} 
}

sub add{
    my ($d1, $d2, $inverted) = @_;
    return ( new PGL::Utils::Date(mjd => $d1->{_mjd} + $d2) );
}

sub subtract{
    my ($d1, $d2, $inverted) = @_;
    return ( new PGL::Utils::Date(mjd => $d1->{_mjd} - $d2) );
}

sub stringify{
    my $self = shift;
    return $self->{_year}.", ".$self->{_doy}
}

#sub numify{
#    return shift -> {_mjd};
#}

1;

