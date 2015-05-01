package PGL::Data::GPS::NavSrc;

use PGL::FTP::RemoteDataSrc;
our @ISA = qw(PGL::FTP::RemoteDataSrc);

use strict;
use warnings;

sub new {
    shift->SUPER::new(
                       host     => "cddis.gsfc.nasa.gov",
                       user     => "anonymous",
                       password => "anonymous",
                       path     => "/gps/data/daily/yyyy/brdc/#key#doy0.yyn.Z",
                       debug    => 0
                      );
}

1;

