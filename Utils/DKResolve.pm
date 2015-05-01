package DKResolve;


use Carp;
use POSIX;
use strict;
use warnings;

sub resolve{
    
    my $keyWord = undef;
    my $date    = undef;
    my $string  = undef;
    
    my $pkgName = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    while (my ($key,$value) = each(%kwargs)){
        
        # convert to lower case
        $key = lc($key);
        
        if ($key =~ /^key$/){
            
            $keyWord = $value;
        
        } elsif ($key =~ /^date$/){
            
            # make sure that input is actually a date object
            if ( $value -> isa("PGL::Utils::Date") ){
                
                # if so, then no problem
                $date = $value;
                
            } else {
                
                # uh, we have a problem here
                confess("date keyword value must be a date object\n");
            }
        
        }elsif ( $key =~ /^string$/ ){
            
            # the thing that needs resolved
            $string = $value;
        } 
    }
    
    # make sure that date, keyword, and string are defined now
    if ( ! defined($keyWord) || ! defined($date) || !defined($string) ){
        confess("Must input key, date, and string arguments.");
    }
    
    # OK, now must do string substitution for each date field
    my $sub; 
    
    $sub = $date->year;
    $string =~ s/yyyy/$sub/g;
    $string =~ s/year/$sub/g;
    
    $sub = substr($sub,2);
    $string =~ s/yy/$sub/g;
    
    # retreive the gps date info
    my $gpsWeek    = $date->gpsWeek;
    my $gpsWeekDay = $date->gpsWeekDay;
    
    # make sure week is 4-char
    if ($gpsWeek < 1000) {$gpsWeek = "0".$gpsWeek};
    
    # form the gpsDate (str cat)
    my $gpsDate = $gpsWeek.$gpsWeekDay;
    
    # sub gpsDate first
    $string =~ s/gpsdate/$gpsDate/g;
    
    # make sure the do weekday next
    $string =~ s/gpsweekday/$gpsWeekDay/g;
    
    # now ... do the week
    $string =~ s/gpsweek/$gpsWeek/g;
    
    # insert day of year
    $sub = $date->doyStr;
    $string =~ s/doy/$sub/g;
    
    # finally, insert the day of month
    $sub = $date->day;
    $string =~ s/day/$sub/g;
    
    # finally, finally, insert key last
    # do this to keep name intact from other subs
    $sub = $keyWord;
    $string =~ s/\#key\#/$sub/g;
    
    return $string;
    
}

1;
