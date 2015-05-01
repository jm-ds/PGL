package PGL::Data::GPS::RinexSrc;

use PGL::FTP::RemoteDataSrc;
our @ISA = qw(PGL::FTP::RemoteDataSrc);

use strict;
use warnings;

sub new {
    shift->SUPER::new(
                       host     => "cddis.gsfc.nasa.gov",
                       user     => "anonymous",
                       password => "anonymous",
                       path     => "/gps/data/daily/yyyy/doy/yyd/#key#doy0.yyd.Z",
                       debug    => 0
                      );
}

1;
