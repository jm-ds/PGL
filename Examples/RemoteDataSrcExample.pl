
use strict;
use warnings;

use PGL::Utils::Date;
use PGL::FTP::RemoteDataSrc;

# initialize a data source 
my $src = new PGL::FTP::RemoteDataSrc(
                            host  => "cddis.gsfc.nasa.gov",
                            path  => "/gps/data/daily/yyyy/doy/yyd/#key#doy0.yyd.Z",
                            debug => 0
                           );
                           
print $src,"\n";
                         
# initialize some start date
my $startDate = new PGL::Utils::Date( gpsWeek=> 1042, gpsWeekDay => 2 );

# get 10 days worth of files for station zwen
for (my $date = $startDate; $date<= $startDate+1; $date++){
    $src -> aquire( localDst => "../../../data", withKey  => "zwen", forDate  => $date );
}

# all done
$src->close();
