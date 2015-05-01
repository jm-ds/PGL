package PGL::Data::GPS::Sp3Src;

use PGL::FTP::RemoteDataSrc;
our @ISA = qw(PGL::FTP::RemoteDataSrc);

use strict;
use warnings;

sub new {
    shift->SUPER::new(
                       host     => "cddis.gsfc.nasa.gov",
                       user     => "anonymous",
                       password => "anonymous",
                       path     => "/gps/products/gpsweek/repro1/#key#gpsdate.sp3.Z",
                       debug    => 0
                      );
}

1;
