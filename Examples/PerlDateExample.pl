use strict;
use warnings;
use PGL::Utils::Date;

my $date;

# create a date using any one of the equivalent 
# formats/combinations.  Note that the order of 
# the keyword input args is not important
$date = new PGL::Utils::Date(mjd => 52945);
print $date,"\n";

$date = new PGL::Utils::Date(fyear => 2003.8369);
print $date,"\n";

$date = new PGL::Utils::Date(Year => 2003, doy => 306);
print $date,"\n";

$date = new PGL::Utils::Date(day => 2, month => 11, year => 2003);
print $date,"\n";

$date = new PGL::Utils::Date(gpsWeek => 1243, gpsWeekDay => 0);
print $date,"\n";

# access date infomation example
print "day: "       , $date -> day       , "\n";
print "doy: "       , $date -> doy       , "\n";
print "mjd: "       , $date -> mjd       , "\n";
print "year: "      , $date -> year      , "\n";
print "fyear: "     , $date -> fyear     , "\n";
print "month: "     , $date -> month     , "\n";
print "gpsWeek: "   , $date -> gpsWeek   , "\n";
print "gpsWeekDay: ", $date -> gpsWeekDay, "\n";

# compare date objects
my $d1 = new PGL::Utils::Date(Year => 1999,   doy => 174);
my $d2 = new PGL::Utils::Date(gpsWeek => 996, gpsWeekDay => 4);

if    ($d1 == $d2){ print "date1 equal to date2\n";        }
elsif ($d1  < $d2){ print "date1 is less than date2\n";    }
elsif ($d1  > $d2){ print "date1 is greater than date2\n"; }

# arithmetic w/overloaded operators on date objects
print   $date,     "\n";
print ++$date,     "\n";
print   $date + 1, "\n";
print   $date - 1, "\n";
print --$date,     "\n";

# use date obj arithmetic and comparisons for iteration
my $startDate = new PGL::Utils::Date(gpsWeek => 1094, gpsWeekDay => 3);

# iterate over range of dates 
for (my $i = $startDate; $i <= $startDate+7; $i++){
    
    # print the i'th date in the range
    print $i,", ";
    
    # use helper function to print 3-digit doy strings
    print $i->doyStr,"\n";
}

# what am I?
print $date->isa("PGL::Utils::Date"),"\n";
