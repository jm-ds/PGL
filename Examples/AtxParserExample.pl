
use strict;
use warnings;

# import the parser
use PGL::Parsers::ATX;

# import fortran formatting modula
use PGL::Fortran::Format;

# import date modual 
use PGL::Utils::Date;

# define the file to parse
my $atxFile = "../DB/ATX/igs08_1667_plus.atx";

# initialize the parser with the atx file 
my $atxParser = new PGL::Parsers::ATX(file => $atxFile);

# parse the atx file
$atxParser -> parse();

# init antenna
my $antennaType = "AOAD/M_T";
   $antennaType = "JAV_TRIUMPH-1";
   $antennaType = "ASH700228A+EX";
#   $antennaType = "NOV702_2.02";
my $domeType    = "JSPA";

# make sure our antenna w/ dome exists
if( ! $atxParser -> exists( antenna => $antennaType, withDome => $domeType ) ){
    
    # if not, see if this antenna w/ no dome exists
    if ($atxParser -> exists( antenna => $antennaType, withDome => "NONE" ) ){
        
        # tell the user we're defaulting to no dome
        warn("dome $domeType not found for antenna $antennaType, will use NONE instead\n");
        
        # OK, so set the dome type to none
        $domeType = "NONE";
    
    } else {
        # otherwise toss out the station or something like stop procesing etc
        die ("Could not find $antennaType  $domeType nor $antennaType  NONE in ATX file $atxFile\n");
    }
}

# access antenna phase center offsets
my ($n1, $e1, $u1) = (undef,undef,undef);
my ($n2, $e2, $u2) = (undef,undef,undef);

($n1, $e1, $u1) = $atxParser -> getOffset (
                                           forAntenna => $antennaType, 
                                           havingDome => $domeType, 
                                           forFreq    => "L1"
                                          );
                                             
($n2, $e2, $u2) = $atxParser -> getOffset (
                                           forAntenna => $antennaType, 
                                           havingDome => $domeType, 
                                           forFreq    => "L2"
                                          );

# let the user know about these wonderful numbers
print "L1 phase center offset (neu): $n1 $e1 $u1\n";
print "L2 phase center offset (neu): $n2 $e2 $u2\n";

# get L1 PCV map (hash ref of array refs)
my $pcvL1 = undef;
my $pcvL2 = undef;

# get L1 PCV map (hash ref of array refs)
$pcvL1 = $atxParser -> getPCV( 
                               forAntenna => $antennaType,
                               havingDome => $domeType,
                               forFreq    => "L1"
                             );
                                
# get L2 PCV map (hash ref of array refs)
$pcvL2 = $atxParser -> getPCV( 
                               forAntenna => $antennaType,
                               havingDome => $domeType,
                               forFreq    => "L2"
                             );
                                
# for more info about using hash and array references 
# see:   http://perldoc.perl.org/perlreftut.html 
# sort the PCV entries by azmuthal angles clockwise
foreach my $azAngle ( sort {$a<=>$b} keys %{$pcvL1} ){
    
    # get azimuthal-dependant pattern for all zenith angles
    my @pattern =  @{ ${$pcvL1} {$azAngle} };

    # just simply print out the values
    foreach my $value ( @pattern ){
        printf("%7.2f ",$value);
    }

    print "\n";
}

# Typically this is all you need.  But suppose you wanted
# to access the pattern by zenith angle and THEN azimuth angle
# you'll need to get the zenith angles first from the atx parser
my ($zen1, $zen2, $dzen) = $atxParser -> getZenithAngles(
                                                         forAntenna => $antennaType,
                                                         havingDome => $domeType
                                                        );
                                                      
# likewise you can get the azimuthal angles also
my ($azi1, $azi2, $dazi) = $atxParser -> getAzimuthalAngles(
                                                            forAntenna => $antennaType,
                                                            havingDome => $domeType
                                                           );
                                                           
# finall, you can (for your convenience) get the antphc header line
my $headerANTPHC = $atxParser -> getAntphcHeader(
                                                 forAntenna => $antennaType,
                                                 havingDome => $domeType,
                                                 withFreq   => "L1"
                                                );
                                                           
# initialize variables   
my $value      = undef;
my $valueL1    = undef;
my $valueL2    = undef;

# print the antphc header
printf("ANTNO=DD   #%-16s%4s\n",$antennaType,
                                $domeType     );
printf("%s\n"                  ,$headerANTPHC );

# store the pattern values here
my @pattern;

# used the zenith angles for the antenna to define the iteration
for (my $i = $zen1; $i <= $zen2/$dzen; $i++){
    
    # now simply reuse the previous example to 
    # access each azmuthal pattern one by one ..
    # 
    # could also use the azi angles to define loop as:
    #  for (my $j = $azi1; $j <= $azi2; $j += $dazi)
    foreach my $azAngle ( sort {$a<=>$b} keys %{$pcvL1} ){
        
        # do not print azi angles for 360 degrees for antphc
        if ($azAngle == 360) { next; }; 

        # get azimuthal-dependant pattern for all zenith angles
        # ${$pcvL1}{$azAngle} -> [$i] is also valid
        $valueL1 = @{${$pcvL1}{$azAngle}}[$i];
        $valueL2 = @{${$pcvL2}{$azAngle}}[$i];
    
        # make some PCV for a linear combinations 
        # of L1 and L2, say iono-free 
        $value = 2.5457 * $valueL1 - 1.5457 * $valueL2;
        
        # that's all ... store value in meters
        push(@pattern,$value/1000);    
    }    
}

# print the values in antphc format
print(PGL::Fortran::Format -> new("8D10.4") -> write(@pattern));

 
my $date = undef;
my $prn  = undef;
my $svn  = undef;

# create date we're going to work with 
$date = new PGL::Utils::Date(year => 2009, month => 9, day => 13);

# say we need to get which satellite number corresponds to PRN ...
$prn = "G19";

# see if your PRN actually exists for given date
if ( $atxParser -> exists(prn => $prn, forDate => $date) ){
    
    # FORWARD: get the SVN that corresponds to PRN for date (returns SVN or undef)
    $svn =  $atxParser -> resolve( prn => $prn, forDate => $date);
    
    # REVERSE: get the PRN that corresponds to the SVN (returns PRN or undef)
    $prn = $atxParser -> resolve( svn => $svn);

    # blab about it
    print "On $date $prn <--> $svn\n";
    
} else {
    
    # yell at the user about it
    die(" PRN $prn does not exist for $date\n");
}

# access SV antenna phase center offsets
my ($x1, $y1, $z1) = (undef,undef,undef);
my ($x2, $y2, $z2) = (undef,undef,undef);

($x1, $y1, $z1) = $atxParser -> getOffset (
                                           prn        => $prn, 
                                           forDate    => $date,
                                           forFreq    => "L1"
                                          );
                                             
($x2, $y2, $z2) = $atxParser -> getOffset (
                                           prn        => $prn, 
                                           forDate    => $date,
                                           forFreq    => "L2"
                                          );

# let the user know about these wonderful numbers
print "The L1 mean antenna phase center relative to the center of mass of the satellite (XYZ in [mm]): $x1 $y1 $z1\n";
print "The L2 mean antenna phase center relative to the center of mass of the satellite (XYZ in [mm]): $x2 $y2 $z2\n";

# get L1 PCV map for PRN on date using resolved SVN
$pcvL1 = $atxParser -> getPCV( 
                               svn        => $svn,
                               forFreq    => "L1"
                             );
                                
# get L2 PCV map PRN on date using resolved SVN
$pcvL2 = $atxParser -> getPCV( 
                               svn        => $svn,
                               forFreq    => "L2"
                             );
                                
# sort the PCV entries by azmuthal angles clockwise
foreach my $azAngle ( sort {$a<=>$b} keys %{$pcvL1} ){
    
    # get azimuthal-dependant pattern for all zenith angles
    my @pattern =  @{ ${$pcvL1} {$azAngle} };

    # just simply print out the values
    foreach my $value ( @pattern ){
        printf("%7.2f ",$value);
    }

    print "\n";
}

($zen1, $zen2, $dzen) = $atxParser -> getZenithAngles(
                                                       svn        => $svn,
                                                       forFreq    => "L2"
                                                     );
                                                      
# likewise you can get the azimuthal angles also
($azi1, $azi2, $dazi) = $atxParser -> getAzimuthalAngles(
                                                         svn        => $svn,
                                                         forFreq    => "L2"
                                                        );
                                                           
# finall, you can (for your convenience) get the antphc header line
$headerANTPHC = $atxParser -> getAntphcHeader(
                                              svn        => $svn,
                                              withFreq   => "L1"
                                             );
                                                           
# initialize variables   
$value      = undef;
$valueL1    = undef;
$valueL2    = undef;

# print the antphc header
printf("ANTNO=DD   #%-16s%4s\n",$prn,
                                $svn     );
printf("%s\n"                  ,$headerANTPHC );

# store the pattern values here
@pattern = ();

# used the zenith angles for the antenna to define the iteration
for (my $i = $zen1; $i <= $zen2/$dzen; $i++){
    
    # now simply reuse the previous example to 
    # access each azmuthal pattern one by one ..
    # 
    # could also use the azi angles to define loop as:
    #  for (my $j = $azi1; $j <= $azi2; $j += $dazi)
    foreach my $azAngle ( sort {$a<=>$b} keys %{$pcvL1} ){
        
        # do not print azi angles for 360 degrees for antphc
        if ($azAngle == 360) { next; }; 

        # get azimuthal-dependant pattern for all zenith angles
        # ${$pcvL1}{$azAngle} -> [$i] is also valid
        $valueL1 = @{${$pcvL1}{$azAngle}}[$i];
        $valueL2 = @{${$pcvL2}{$azAngle}}[$i];
    
        # make some PCV for a linear combinations 
        # of L1 and L2, say iono-free 
        $value = 2.5457 * $valueL1 - 1.5457 * $valueL2;
        
        # that's all ... store value in meters
        push(@pattern,$value/1000);    
    }    
}

# print the values in antphc format
print(PGL::Fortran::Format -> new("8D10.4") -> write(@pattern));

#
# GLONASS Example
#

# create date we're going to work with 
$date = new PGL::Utils::Date(year => 2009, month => 9, day => 13);

# say we need to get which satellite number corresponds to PRN ...
$prn = "R04";

# see if your PRN actually exists for given date
if ( $atxParser -> exists(prn => $prn, forDate => $date) ){
    
    # FORWARD: get the SVN that corresponds to PRN for date (returns SVN or undef)
    $svn =  $atxParser -> resolve( prn => $prn, forDate => $date);
    
    # REVERSE: get the PRN that corresponds to the SVN (returns PRN or undef)
    $prn = $atxParser -> resolve( svn => $svn);

    # blab about it
    print "On $date $prn <--> $svn\n";
    
} else {
    
    # yell at the user about it
    die(" PRN $prn does not exist for $date\n");
}

# get R1 PCV map for PRN on date using resolved SVN
$pcvL1 = $atxParser -> getPCV( 
                               svn        => $svn,
                               forFreq    => "R01"
                             );
                                
# get R2 PCV map PRN on date using resolved SVN
$pcvL2 = $atxParser -> getPCV( 
                               svn        => $svn,
                               forFreq    => "R02"
                             );
                                
# sort the PCV entries by azmuthal angles clockwise
foreach my $azAngle ( sort {$a<=>$b} keys %{$pcvL1} ){
    
    # get azimuthal-dependant pattern for all zenith angles
    my @pattern =  @{ ${$pcvL1} {$azAngle} };

    # just simply print out the values
    foreach my $value ( @pattern ){
        printf("%7.2f ",$value);
    }

    print "\n";
}

# initialiaze a list of PRNs
my @prnList;

# ask the parser for all GPS sNN for date
@prnList = $atxParser -> getPrns( forDate => $date, forConstellation => "gps" );

# print ANTPHC entries for all PRNs
foreach my $prn (@prnList){
    
    # get the SVN associated with this PRN
    $svn = $atxParser -> resolve(prn => $prn, forDate => $date);
    
    ($zen1, $zen2, $dzen) = $atxParser ->    getZenithAngles( svn => $svn, forFreq => "L1" );        
    ($azi1, $azi2, $dazi) = $atxParser -> getAzimuthalAngles( svn => $svn, forFreq => "L1" );
    $headerANTPHC         = $atxParser ->    getAntphcHeader( svn => $svn, forFreq => "L1" );
    $pcvL1                = $atxParser ->             getPCV( svn => $svn, forFreq => "L1" );
    $pcvL2                = $atxParser ->             getPCV( svn => $svn, forFreq => "L2" );
    
    printf("ANTNO=DD   #%-16s%4s\n",$prn,$svn     );
    printf("%s\n"                  ,$headerANTPHC );
    
    @pattern = ();

    for (my $i = $zen1; $i <= $zen2/$dzen; $i++){

        foreach my $azAngle ( sort {$a<=>$b} keys %{$pcvL1} ){

            if ($azAngle == 360) { next; }; 

            $valueL1 = @{${$pcvL1}{$azAngle}}[$i];
            $valueL2 = @{${$pcvL2}{$azAngle}}[$i];
            $value   = 2.5457 * $valueL1 - 1.5457 * $valueL2;

            push(@pattern,$value/1000);    
        }    
    }

    print(PGL::Fortran::Format -> new("8D10.4") -> write(@pattern));
}
