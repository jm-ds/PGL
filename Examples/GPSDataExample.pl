
use strict;
use warnings;

use PGL::Utils::Date;
use PGL::Data::GPS::Sp3Src;
use PGL::Data::GPS::NavSrc;
use PGL::Data::GPS::RinexSrc;

my $sp3Src = new PGL::Data::GPS::Sp3Src();
my $navSrc = new PGL::Data::GPS::NavSrc();
my $rnxSrc = new PGL::Data::GPS::RinexSrc();

my $dst = "../../../data";
my $startDate = new PGL::Utils::Date(year => 2002, month => 2, day => 22);

for (my $date = $startDate; $date <= $startDate + 5; $date++){
    $rnxSrc -> aquire( forDate => $date, withKey => "albh", toDst => $dst );
    $sp3Src -> aquire( forDate => $date, withKey => "ig1",  toDst => $dst );
    $navSrc -> aquire( forDate => $date, withKey => "brdc", toDst => $dst );
}
                 
# clean up
$rnxSrc -> close();
$sp3Src -> close();
$navSrc -> close();
