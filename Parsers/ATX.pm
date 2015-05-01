package PGL::Parsers::ATX;

=head1 NAME
 
  PGL::Parsers::ATX - Parse Antenna Exchange files
 
=head1 SYNOPSIS
 
    # import the parser
    use PGL::Parsers::ATX;
 
    # define the file to parse
    my $atxFile = "../../../data/igs08.atx";
    
    # initialize the parser with the atx file 
    my $atxParser = new PGL::Parsers::ATX(file => $atxFile);
    
    # parse the atx file
    $atxParser -> parse();
    
=head1 DESCRIPTION

    API for interacting with Antenna Exchange files (ATX)
    for GPS SV, GLONASS SV, and ground station antennas.
    
    Almost all functions interact with the basic key-words:
    
    Gound station antennas
    ----------------------
    
    antenna  => 
    withDome =>
    forFreq  =>
    
    GPS and Glonass Antennas
    ------------------------
    
    prn     => 
    forDate =>
    svn     =>
    
    ------------------------
    
    where typically either prn + date *or* svn are used 
    to define SV antenna (not both).  The function "resolve"
    can translate between svn <=> prn + date.
    
    NOTE:  date isa PGL::Utils::Date object  
    
    Typically, visible SVs are listed as PRNs in the Rinex file
    located in the header for each observation:
    
                                   |---------- PRNs ------------|
    06  7 20  0  0  0.0000000  0 10G03G18G06G22G19G27G07G21G16G15
  21061861.004    21061855.254   -20633263.40707 -16072706.05947        50.000
        42.000        2011.875        1567.695
  22038131.563    22038125.413   -17242555.26407 -13430273.47347        50.000
        39.000        1268.272         988.264
  24495034.031    24495030.495    -2470791.96604  -2111522.84646        38.000
        22.000       -3035.493       -2365.319
        
        ....
        
    Here, this rinex observation header says it is an observation
    for year 2006, month 7, day, 20, hour 0, minute 0, second 0.000000
    
    The next number, 0, indicates no cycle slips (usually ignored anyway)
    
    Finally, the visible SVs are listed as 10G03G18G06G22G19G27G07G21G16G15
    
        10 is the total number of SVs included in this observation record
        and these 10 SVs PRN ids are G03 G18 G06 G22 G19 G27 G07 G21 G16 G15  
    
    Therefore, to access the SVs Phase Centre Offset (PCO) and Phase Centre Variations (PCV)
    
    # create date object the corresponds to date of observations
    my $date = new PGL::Utils::Date(year => 2006, month => 7, day => 20);
    
    # we want this PRN
    my $PRN = 'G22';
    
    # check that PRN for this date is defined in the ATX file
    $atxParser -> exists(prn => $prn, forDate => $date);
    
    # init SVs PCO
    my ($x1, $y1, $z1) = (undef,undef,undef);
    
    # get the L1 phase centre offsets w.r.t SV centre of mass (XYZ in [mm])
    ($x1, $y1, $z1) = $atxParser -> getOffset (
                                               prn        => $prn, 
                                               forDate    => $date,
                                               forFreq    => "L1"
                                              );
                                              
    # finally, get L1 PCV for this PRN 
    $pcvL1 = $atxParser -> getPCV( 
                                   prn     => $prn,
                                   forDate => $date,
                                   forFreq => "L1"
                                 );
                                 
    Likewise the Rinex file header will typically list an antenna + dome 
    The PCO and PCV can be accessed in exactly the same fashion using 
    the ground station key-words listed above
    
             2.1            OBSERVATION DATA    G (GPS)             RINEX VERSION / TYPE
        GPSBASE 2.10 2270                       19-Jul-06 23:59:47  PGM / RUN BY / DATE
        ZIMM                                                        MARKER NAME
        14001M004                                                   MARKER NUMBER
        GPSBASE             SWISSTOPO                               OBSERVER / AGENCY
        4526253099          TRIMBLE NETRS       Nav  1.15 / Boot  1 REC # / TYPE / VERS
             0                                                      RCV CLOCK OFFS APPL
        99390               TRM29659.00     NONE                    ANT # / TYPE
          4331297.3390   567555.6380  4633133.7170                  APPROX POSITION XYZ
                0.0000        0.0000        0.0000                  ANTENNA: DELTA H/E/N
             1     1     0                                          WAVELENGTH FACT L1/2
             8    C1    P2    L1    L2    S1    S2    D1    D2      # / TYPES OF OBSERV
            30.000                                                  INTERVAL
          2006     7    20     0     0    0.0000000     GPS         TIME OF FIRST OBS
                                                                    END OF HEADER
                                                                    
    So we can see this Rinex file will require PCO+PCV 
    for antenna + dome =  TRM29659.00     NONE
  
    NOTE:  Metadata listed in Rinex file headers should be used with caution 
           b/c typically rnx headers are not well maintained.
            
=head2 Functions
  
=head3 new

    Initialize the parser object:
    
    my $atxParser = new PGL::Parsers::ATX( file => "/some/path/file.atx")
  
=head3 parse

    Must call parse() before accessing PCO and PCV information.

    $atxParser -> parse();
    
=head3 resolve

    figure out SVN given PRN + date 
    
                or
    
    figure out PRN given SVN
    
    # FORWARD: get the SVN that corresponds to PRN for date (returns SVN or undef)
    $svn =  $atxParser -> resolve( prn => $prn, forDate => $date);
    
    # REVERSE: get the PRN that corresponds to the SVN (returns PRN or undef)
    $prn = $atxParser -> resolve( svn => $svn);
  
=head3 exists

    As you might guess checks if an antenna dome combination exists

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
    
    Similarly do this for SVs antennas:
    
    $atxParser -> exists(prn => $prn, forDate => $date)
    $atxParser -> exists(svn => $svn)

=head3 getOffset

    NOTE:  Frequencies names L1 and L2 are aliases for G01 and G02
       officially frequencies L1 => G01, and L2 => G02 as listed in ATX file
       
       So for GLONASS SV and antenna need to use full name R01 and R02
       (e.g forFreq => "R01", or for GPS L2 could use forFreq => "G02", etc)

    Get the RMS phase center variations for both L1 and L2
    
    # get the L1 antenna phase center offset
    my ($n1, $e1, $u1) = $atxParser -> getOffsetNEU (
                                                     forAntenna => $antennaType, 
                                                     havingDome => $domeType, 
                                                     forFreq    => "L1"
                                                    );
                                                 
    my ($n2, $e2, $u2) = $atxParser -> getOffsetNEU (
                                                     forAntenna => $antennaType, 
                                                     havingDome => $domeType, 
                                                     forFreq    => "L2"
                                                    );
                                                    
    *but* notice that when we do this for SV antenna we get the mean antenna phase 
    center relative to the center of mass of the satellite (XYZ in [mm])
    
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
    

=head3 getPCV

    NOTE:  Frequencies names L1 and L2 are aliases for G01 and G02
           officially frequencies L1 => G01, and L2 => G02 as listed in ATX file
           
           So for GLONASS SV and antenna need to use full name R01 and R02
           (e.g forFreq => "R01", or for GPS L2 could use forFreq => "G02", etc)

    Get L1 and L2 phase center variations as a hash ref of array refs
    Each hash key is an azimuthal angle
    Each array is the pattern value at zenith angle defined by zen1, zen2, dzen
    
    # get L1 PCV map (hash ref of array refs)
    my $pcvL1 = $atxParser -> getPCV( 
                                      forAntenna => $antennaType,
                                      havingDome => $domeType,
                                      forFreq    => "L1"
                                    );
                                    
    # get L1 PCV map (hash ref of array refs)
    my $pcvL2 = $atxParser -> getPCV( 
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
            print $value," "
        }
    
        print "\n";
    }
    
    Works exactly the same for SV antenna 
    
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
                                    
=head3 getZenithAngles

    # ground station antenna
    my ($zen1, $zen2, $dzen) = $atxParser -> getZenithAngles(
                                                         forAntenna => $antennaType,
                                                         havingDome => $domeType
                                                        );
                                                        
    # SV antenna
    ($zen1, $zen2, $dzen) = $atxParser -> getZenithAngles(
                                                       svn        => $svn,
                                                       forFreq    => "L2"
                                                     );

=head3 getAzimuthalAngles

    # ground station antenna
    my ($azi1, $azi2, $dazi) = $atxParser -> getAzimuthalAngles(
                                                         forAntenna => $antennaType,
                                                         havingDome => $domeType
                                                        );
                                                        
    # SV antenna
    ($azi1, $azi2, $dazi) = $atxParser -> getAzimuthalAngles(
                                                           svn        => $svn,
                                                           forFreq    => "L2"
                                                        );

=head3 getAntphcHeader

    # SV antenna
    $headerANTPHC = $atxParser -> getAntphcHeader(
                                                 svn        => $svn,
                                                 withFreq   => "L1"
                                                );

    # ground station antenna
    my $headerANTPHC = $atxParser -> getAntphcHeader(
                                                     forAntenna => $antennaType,
                                                     havingDome => $domeType,
                                                     withFreq   => "L1"
                                                    );
                                                   
    printf("ANTNO=DD   #%-16s%4s\n",$antennaType,
                                    $domeType     );
    printf("%s\n"                  ,$headerANTPHC );
    
    Prints out the header as:
    
    ANTNO=DD   #ASH700228A+EX   NONE
      19   0.00   5.00  72   0.00   5.00
  
  
   The rest of the ANTPHC can be printed as follows:
   
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
            
            # that's all
            push(@pattern,$value/1000);    
        }    
    }
    
    # print the values in antphc format
    print(PGL::Fortran::Format -> new("8D10.4") -> write(@pattern));
    
=head3 getPrns

    my @prnArray = $atxParser -> getPrns(forDate => $date, forConstellation => "gps");
    my @prnArray = $atxParser -> getPrns(forDate => $date, forConstellation => "glonass");
    my @prnArray = $atxParser -> getPrns(forDate => $date, forConstellation => "galileo");

    
=head1 AUTHOR

    Abel Brown (brown.2179@gmail.com)
    
    12/15/2011
    
=head1 SEE ALSO

    Code:
        PGL::Fortran::Format
        PGL::Examples::AtxParserExample.pl
    
    Fortran format:
        http://search.cpan.org/~itub/Fortran-Format-0.90/Format.pm
        http://www.fortran.com/fortran/F77_std/rjcnf0001-sh-13.html
        
    References:
        http://igscb.jpl.nasa.gov/igscb/station/general/antex14.txt
    

 
=cut

use Carp;
use strict;
use warnings;
use IO::File;
use PGL::Utils::Date;

sub new {
    
    # get the class name
    my $class = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    # initialize self hash
    my $self = { 
                 atx  => undef,
                 file => undef 
               };
      
    # parse keyword input arguments         
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        # make sure the key is lower case
        $key = lc($key);
        
        # look for a file keyword
        if ($key =~ /^file$/ || $key =~ /^atxfile$/){
            
            # make sure the file exists 
            if (! -f $value){
                # if not the yell at the user about it
                confess('File $value does not exist\n');
            }
            
            # set the file to be parsed
            $self -> {file} = $value;
            
        } else {
         
         # no clue what this is so yell at the user 
         carp("Unrecognized input key: $key, with value: $value\n");
        }
    }
    
    # that's all folks
    return bless($self,$class);
}

sub parse{
    
    # NOTE: use IO::File for readability
    
    # init variable for holding current line
    my $line = undef;
    
    # init parsing variables
    my $junk        = undef;
    
    my $antennaName = undef;
    my $domeType    = undef;
    my $dazi        = undef;
    my $zen1        = undef;
    my $zen2        = undef;
    my $dzen        = undef;
    my $nzen        = undef;
    my $freq        = undef;
    my $north       = undef;
    my $east        = undef;
    my $up          = undef;
    
    my $svAntType   = undef;
    my $prn         = undef;
    my $svn         = undef;
    
    my $year        = undef;
    my $month       = undef;
    my $day         = undef;
    my $hour        = undef;
    my $min         = undef;
    my $sec         = undef;
    
    my $validFrom   = undef;
    my $validUntil  = undef;
    
    my $shouldProcessLine = 1;
    my $zero              = 0;
    
    # get reference to this
    my $self = shift;
    
    # open the ATX file for reading
    my $fid = IO::File -> new($self -> {file},"r")
        or confess("Could not open file ",$self->{file},"\n");
        
    # loop over all the lines
    while ( defined ( $line = $fid -> getline() ) ){
        
        # remove white spaces and trailing new lines
        chomp($line);
        
        # reset the dates if we're at the new antenna
        if ($line =~/START OF ANTENNA/){
            
            # this value *must*  be specified for SV antenna
            $validFrom  = undef;
            
            # set default end time (not required to be defined in sv def)
            $validUntil = new PGL::Utils::Date(year => 2050, doy => 1);
        }

        # parse the antenna name and dome type for ground stations
        ($antennaName, $domeType, $junk) = split(/\s+/,$line) 
            if $line =~ /TYPE \/ SERIAL NO/;
            
        # try to parse out the line for GPS SV antennas
        if ($line =~ m/^(BLOCK\s.+)\s+(G\d+)\s+(G\d+)\s+(\d+-\d+\w)\s+TYPE \/ SERIAL NO\s+$/){
            
            # here assign SV antenna header info
            $svAntType = $1; $prn = $2; $svn = $3;
            
            # force the antenna name and dome type 
            $antennaName = $prn; $domeType    = $svn;
        }
        
        # try to parse out the line for GLONASS SV antennas
        if ($line =~ m/^(GLONASS.+?)\s+(R\d+)\s+(R\d+)\s+(\d+-\d+\w)\s+TYPE \/ SERIAL NO\s+$/){
            
            # here assign SV antenna header info
            $svAntType = $1; $prn = $2; $svn = $3;
            
            # force the antenna name and dome type 
            $antennaName = $prn; $domeType    = $svn;
        }
        
        # Here need to parse the Valid From lines
        if ($line =~ /VALID FROM/){
            
            # parse the data + time information
            ($year,$month,$day,$hour,$min,$sec) = ($line =~ m/(\d+)/g);
            
            # init the start date for the SV antenna entry
            $validFrom = new PGL::Utils::Date(year => $year, month => $month, day => $day);
        }
        
        # Here need to parse the valid until lines
        if ($line =~ /VALID UNTIL/){
            
            # parse the data + time information
            ($year,$month,$day,$hour,$min,$sec) = ($line =~ m/(\d+)/g);
            
            # init the start date for the SV antenna entry
            $validUntil = new PGL::Utils::Date(year => $year, month => $month, day => $day);
        }
                
        # parse the azmuthal angle step size
        ($junk, $dazi, $junk ) = split(/\s+/,$line) 
            if $line =~ /DAZI/;
        
        # parse the zenith angle start, stop and step
        ($junk,$zen1, $zen2, $dzen,$junk) = split(/\s+/, $line) 
            if $line =~ /ZEN1 \/ ZEN2 \/ DZEN/;
            
        # guard against "G 1", "R 2" etc by substituting
        # in the appropriate "G01", "G02", "R01", etc 
        # be sure to do this before actually parsing the freq.
        $line =~ s/\b([GR])\s([1-9])\b/$1$zero$2/
            if $line =~ /START OF FREQUENCY/;
            
        # parse which frequency we're in, eg. G01, R02 etc
        ($junk, $freq, $junk) = split(/\s+/, $line)
            if $line =~ /START OF FREQUENCY/;
          
        # parse the antenna phase center offset for frequency  
        ($junk,$north,$east,$up,$junk) = split(/\s+/, $line) 
            if $line =~ /NORTH \/ EAST \/ UP/;
            
        # toggle shouldProcessLine if in Frequency RMS section.
        # NOTE: This matches both START and END of FREQ RMS
        $shouldProcessLine = !$shouldProcessLine
            if $line =~ /OF FREQ RMS/;
            
        if ($line =~ /NOAZI/ and $shouldProcessLine){
            
            # initialize the antenna entrys
            $self -> {atx}{$antennaName}{$domeType}{"dazi"} = $dazi;
            $self -> {atx}{$antennaName}{$domeType}{"zen1"} = $zen1;
            $self -> {atx}{$antennaName}{$domeType}{"zen2"} = $zen2;
            $self -> {atx}{$antennaName}{$domeType}{"dzen"} = $dzen;
            
            $self -> {atx}{$antennaName}{$domeType}{$freq}{"offset"}{"up"}    = $up;
            $self -> {atx}{$antennaName}{$domeType}{$freq}{"offset"}{"east"}  = $east;
            $self -> {atx}{$antennaName}{$domeType}{$freq}{"offset"}{"north"} = $north;
            
            $self -> {atx}{$antennaName}{$domeType}{"validFrom"}  = $validFrom;
            $self -> {atx}{$antennaName}{$domeType}{"validUntil"} = $validUntil;
            
            # compute the number of zenith angles there 
            # should be in each of the pcv data lines
            $nzen = ($zen2 - $zen1)/$dzen + 1;
            
            # parse the noazi data line pulling out only numbers
            my @dataEntries = ($line =~ m/(-?\d+\.\d+)/g);
 
            # check that the number of data entries 
            # matches header definition
            my $numDataEntries = scalar(@dataEntries);
            if (scalar(@dataEntries) != $nzen){
                carp("Invalid PCV data line",
                     " for antenna ",   $antennaName,
                     " with dome ",     $domeType, 
                     " for freq ",      $freq,
                     " at azml angle ", "NOAZI.  ",
                     " Expected $nzen but only parsed $numDataEntries)\n",
                     " LINE: $line",
                     "\n");
            }
            
            # store the noazi PCV entries
            $self -> {atx}{$antennaName}{$domeType}{$freq}{'NOAZI'} = [@dataEntries];
                
            # see if there are any remaining pcv data lines
            if ($dazi == 0){ next; }
                
            # compute the number of remaining data lines 
            my $numLines = (360/$dazi) + 1;  
            
            # parse the remaining data lines  
            for (my $i = 0; $i < $numLines; $i++){
                
                # get the next data line
                $line = $fid -> getline();
                                
                # parse the data pulling out only numbers
                my @dataEntries = ($line =~ m/(-?\d+\.\d+)/g);
                
                # get the azmuthal angle (clockwise direction)
                # this is the first number of the data line
                my $azmuthalAngle = shift @dataEntries;
                
                # make sure that the number of pcv entries for 
                # this line actually matches the number of entries
                # defined in the header
                if( scalar(@dataEntries) != $nzen){
                    carp("Invalid PCV data line",
                         " for antenna ",   $antennaName,
                         " with dome ",     $domeType, 
                         " for freq ",      $freq,
                         " at azml angle ", $azmuthalAngle,
                         "\n");
                }
                
                # now store the pcv information 
                $self -> {atx}{$antennaName}{$domeType}{$freq}{'pcv'}{$azmuthalAngle} = [@dataEntries];
                   
            }
        }
    }  
}

sub resolve{
    
    # get class reference
    my $self = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    # init
    my $svn         = undef;
    my $prn         = undef;
    my $date        = undef;    
    my $antennaName = undef;
    my $domeType    = undef;
    my $freq        = undef;
    
    my $validFrom   = undef;
    my $validUntil  = undef;
    
    my $returnValue = undef;
    
    # parse out the keyword args 
    # NOTE: dont use __parseKwArgs cuz probably recursive etc
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        # make sure the key is lower case
        $key  = lc($key);
        
        # parse the SVN
        if ($key =~/^svn$/ or $key =~ /^forsvn$/) {           
                $svn = $value;
        
        # parse the PRN       
        } elsif ($key =~ /^prn$/ or $key =~ /^forprn$/){
            $prn = $value;
            
        # arse the DATE 
        } elsif ($key =~ /^date$/ or $key =~ /^fordate$/ 
                    or $key =~/^havingdate$/ or $key =~ /^withdate$/){
                        
            # make sure that input is actually a date object
            if ( ref($value) eq "PGL::Utils::Date" ){ 
                
                # no problem
                $date = $value;
                 
            } else {
                
                # yell at the user b/c we need a date object! 
                confess("date keyword value must be a date object\n");
            }
        
        # don't know what this is so nothing to do                 
        } else {
            
            # no clue what this is so yell at the user 
            carp("Unrecognized input key: $key, with value: $value\n");
        }
    }
            
    # OK, figure out what we have 
    if (defined $prn and defined $date){
        
        # loop through each SVN for the given PRN
        # until we've found an SVN that matches 
        # the given date
        for my $tmpSvn ( keys %{ $self->{atx}{$prn} } ){
            
            # get dates for candidate SVN
            $validFrom  = $self -> {atx}{$prn}{$tmpSvn}{"validFrom"};
            $validUntil = $self -> {atx}{$prn}{$tmpSvn}{"validUntil"};
            
            # see if these dates match given date
            if ($validFrom <= $date and $date <= $validUntil){
                $returnValue = $tmpSvn;
                last;
            }
        }
        
    } elsif (defined $svn){
        
        # loop over all SVN of all PRN to see if we can match the SVN
        # Note that this is basically loop all antennas until we find
        # a match for the domeType but nice to think about PRN and SVN
        for my $tmpPrn (keys %{ $self -> {atx} }){
            for my $tmpSvn (keys %{ $self->{atx}{$tmpPrn} }){
                if ($tmpSvn eq $svn){
                    $returnValue = $tmpPrn;
                    last;
                }
            }
        }
    }
    
    return $returnValue;
}

sub __parseKwArgs{
    
    # get reference to self
    my $self  = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    my $antennaName = undef;
    my $domeType    = undef;
    my $freq        = undef;
    
    my $prn         = undef;
    my $svn         = undef;
    my $date        = undef;

    # parse the kwargs
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        # make sure the key is lower case
        $key  = lc($key);
        
        # make sure the value is upper case
        #$value = uc($value);
        
        # parse the antenna type
        if ($key =~ /^antenna$/ or $key =~ /^forantenna$/){
            # set the antenna type
            $antennaName = $value;
                            
        # parse the dome type
        } elsif ($key =~ /^dome$/ or $key =~ /^withdome$/ 
                    or $key =~ /^fordome$/ or $key =~ /^havingdome$/
                        or $key =~ /^dometype$/){
            # set the dome type
            $domeType = $value;
                        
        # parse which frequence e.g. G01, G02, R01, R02 etc
        } elsif ($key  =~ /^freq$/ or $key =~ /^withfreq$/ 
                    or $key =~ /^forfreq$/ or $key =~ /havingfreq/){
            # help choose the frequecy
            if($value eq "L1") {
                $value = "G01";
            } elsif ($value eq "L2"){
                $value = "G02";
            }
            
            # set the frequency
            $freq = $value;  
            
        } elsif ($key =~/^svn$/ or $key =~ /^forsvn$/) { 
            
            $svn = $value;
            
        } elsif ($key =~ /^prn$/ or $key =~ /^forprn$/){
            
            $prn = $value;
            
        } elsif ($key =~ /^date$/ or $key =~ /^fordate$/ 
                    or $key =~/^havingdate$/ or $key =~ /^withdate$/){
                        
            # make sure that input is actually a date object
            if ( ref($value) eq "PGL::Utils::Date" ){ 
                $date = $value; 
            } else {
                # yell at the user 
                confess("date keyword value must be a date object\n");
            }
            
                         
        } else {
            
            # no clue what this is so yell at the user 
            carp("Unrecognized input key: $key, with value: $value\n");
        }
    }
    
    # now the tricky business ...
    # if user specified SVN or PRN then need to make sure that 
    # antennaName and domeType are set so as to point to the correct entry
    # since SV antennas are stored as $self -> {atx}{prn}{svn}
    if (defined $prn and defined $date){
        
        # set the antenna to be the PRN
        $antennaName = $prn;
        
        # set the dome to be the SVN that correspones to PRN for date
        $domeType = $self -> resolve( prn => $prn, forDate => $date );
        
        #print "fuck, $prn, $date\n";
        
    } elsif (defined $svn){
        
        # again, set domeType to be the SVN
        $domeType = $svn;
        
        # figure out which PRN corresponds to this SVN
        $antennaName = $self -> resolve( svn => $svn ) 
    }
    
    # that's a [w]rap ...
    return ($antennaName, $domeType, $freq, $prn, $svn, $date);
}

sub exists {
    
    my $self = shift;
    
    # parse the input arguments
    my ($antennaType, $domeType, $freq) = $self -> __parseKwArgs(@_);
    
    # make sure at least atenna and dome type are defined
    # note here will NOT default domeType to NONE.
    # Let the user check if dome type exists and choose what
    # to do otherwise
    if (! defined($antennaType) or ! defined($domeType)){
        confess("antenna and dome are required input for to check exists\n");
    }
    
    # OK, just simply check the data store for key definitions
    if (defined $freq){
        return defined($self->{atx}{$antennaType}{$domeType}{$freq});
    } else {
        return defined($self->{atx}{$antennaType}{$domeType});
    }   
}

sub getOffset{
    
    # get reference to this
    my $self = shift;
    
    # parse the input arguments
    my ($antennaType, $domeType, $freq) = $self -> __parseKwArgs(@_);
    
    # make sure at least atenna and dome type are defined
    # note here will NOT default domeType to NONE.
    # Let the user check if dome type exists and choose what
    # to do otherwise
    if (! defined($antennaType) or ! defined($domeType) or ! defined($freq)){
        confess("antenna, dome, and freq are required input to compute PCV offset\n");
    }
    
    return (
            $self ->{atx}{$antennaType}{$domeType}{$freq}{'offset'}{'north'},
            $self ->{atx}{$antennaType}{$domeType}{$freq}{'offset'}{'east'},
            $self ->{atx}{$antennaType}{$domeType}{$freq}{'offset'}{'up'}
           )
}

sub getPCV{
    
    # NOTE: returns a hash of array references with keys = azmuthalAngle (clockwise)
    
    # get reference to this
    my $self = shift;
    
    # parse the input arguments
    my ($antennaType, $domeType, $freq) = $self -> __parseKwArgs(@_);
    
    # make sure at least atenna and dome type are defined
    # note here will NOT default domeType to NONE.
    # Let the user check if dome type exists and choose what
    # to do otherwise
    if (! defined($antennaType) or ! defined($domeType) or ! defined($freq)){
        confess("antenna, dome, and freq are required input to compute PCV\n");
    }
    
    # and we're done ... (NOTE: this is a hash of array references!)
    if ( defined ( $self->{atx}{$antennaType}{$domeType}{$freq}{'pcv'} ) ){
        return $self->{atx}{$antennaType}{$domeType}{$freq}{'pcv'};
    } else {
        # return the NOAZI line as hash ref to an array ref
        return { 0 => $self -> {atx}{$antennaType}{$domeType}{$freq}{'NOAZI'} };
    }
}

sub getZenithAngles{
    
    # get reference to this
    my $self = shift;
    
    # parse the input arguments
    my ($antennaType, $domeType, $freq) = $self -> __parseKwArgs(@_);
    
    # make sure at least atenna and dome type are defined
    # note here will NOT default domeType to NONE.
    # Let the user check if dome type exists and choose what
    # to do otherwise
    if (! defined($antennaType) or ! defined($domeType) ){
        confess("antenna and dome are required input to compute PCV zenith angles\n");
    }
    
    return (
            $self ->{atx}{$antennaType}{$domeType}{"zen1"},
            $self ->{atx}{$antennaType}{$domeType}{"zen2"},
            $self ->{atx}{$antennaType}{$domeType}{"dzen"}
           )
    
}

sub getAzimuthalAngles{
    
    # get reference to this
    my $self = shift;
    
    # parse the input arguments
    my ($antennaType, $domeType, $freq) = $self -> __parseKwArgs(@_);
    
    # make sure at least atenna and dome type are defined
    # note here will NOT default domeType to NONE.
    # Let the user check if dome type exists and choose what
    # to do otherwise
    if (! defined($antennaType) or ! defined($domeType) ){
        confess("antenna and dome are required input to compute PCV zenith angles\n");
    }
    return (
            0,
            360,
            $self ->{atx}{$antennaType}{$domeType}{"dazi"}
           );
}

sub getAntphcHeader{
    
    # get reference to this
    my $self = shift;
    
    # parse the input arguments
    my ($antennaType, $domeType, $freq) = $self -> __parseKwArgs(@_);
    
    # make sure at least atenna and dome type are defined
    # note here will NOT default domeType to NONE.
    # Let the user check if dome type exists and choose what
    # to do otherwise
    if (! defined($antennaType) or ! defined($domeType) ){
        confess("antenna, dome are required input to compute PCV\n");
    }
    
    # just need to return 6 numbers
    #
    #   1. the number of zenith angles
    #   2. the starting zenith angle
    #   3. the step size of the zenith angles
    #
    #   4. the number of azmuthal angles
    #   5. the starting azimuthal anglel
    #   6. the step size of the azimuthal angle
    #
    # The catch here is that for non azimutha 
    # dependant patterns, dazi = 360 (not 0)
    
    # get the start, stop, and step of the zenith angles
    my ($zen1, $zen2, $dzen) = (
            $self ->{atx}{$antennaType}{$domeType}{"zen1"},
            $self ->{atx}{$antennaType}{$domeType}{"zen2"},
            $self ->{atx}{$antennaType}{$domeType}{"dzen"}
       );
       
    # get the azimuthal angle step size
    # start and stop azimuthal angles are always 0 and 360
    my $dazi = $self ->{atx}{$antennaType}{$domeType}{"dazi"};
    
    # compute the number of zenith angles
    my $nzen = ($zen2 - $zen1)/$dzen + 1;
    
    # compute the number of azimuthal angles
    my $nazi = undef;
    if ($dazi == 0){
        $nazi = 1;
        $dazi = 360;
    } else {
        $nazi = ( 360 - 0 ) / $dazi;
    }
    
    return sprintf("%4d%7.2f%7.2f%4d%7.2f%7.2f",$nzen, $zen1, $dzen, $nazi, 0.0, $dazi);
}

sub getPrns{
    
    # get reference to self
    my $self  = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    my @prnArray;
    my $date          = undef;
    my $validFrom     = undef;
    my $validUntil    = undef;
    my $constellation = undef;

    # parse the kwargs
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        # make sure the key is lower case
        $key  = lc($key);
        
        # make sure the value is upper case
        #$value = uc($value);
        
        # parse the antenna type
        if ($key =~ /^date$/ or $key =~ /^fordate$/ 
                    or $key =~/^havingdate$/ or $key =~ /^withdate$/){
                        
            # make sure that input is actually a date object
            if ( ref($value) eq "PGL::Utils::Date" ){ 
                $date = $value; 
            } else {
                # yell at the user 
                confess("date keyword value must be a date object\n");
            }
            
        } elsif ($key =~ /^constellation$/ or $key =~ /^forconstellation$/){
            
            if ($value =~ m/^glonass$/i or $value =~ m/^gps$/i or $value =~ m/^galileo$/i
                    or $value =~ m/^compass$/i or $value =~ m/^qzss$/i or $value =~ m/^sbas$/i){
                $constellation = $value;
            }else {
                confess("Unrecognized constellation: $value ".  
                      "Valid constellations are: GPS, GLONASS, Galileo, Compass, QZSS, and  SBAS\n");
            }
            
        } else {
            
            # no clue what this is so yell at the user 
            carp("Unrecognized input key: $key, with value: $value\n");
        }
    }
    
    # make sure the date has been given
    if (! defined $date){
        confess("Must specify date to compute PRNs avalilable\n");
    }
    
    # go through each entry/key in atx
    for my $prn (keys %{ $self -> {atx} }){
        
        # see if this is an SV entry
        next if $prn !~ m/^[G|R|E|C|J|S]\d\d$/;
        
        if (defined $constellation){
            if ($constellation =~ m/^gps$/i){
                next if $prn !~ m/^G/;
            } elsif ($constellation =~ m/^glonass$/i){
                next if $prn !~ m/^R/;
            } elsif ($constellation =~ m/^galileo$/i){
                next if $prn !~ m/^E/;
            } elsif ($constellation =~ m/^compass$/i){
                next if $prn !~ m/^C/;
            } elsif ($constellation =~ m/^qzss$/i){
                next if $prn !~ m/^J/;
            } elsif ($constellation =~ m/^sbas$/i){
                next if $prn !~ m/^S/;
            }
        }
        
        # OK, now need to make sure the SV entry has 
        # a vald antenna definition to match the date given 
        for my $svn (keys %{ $self->{atx}{$prn} }){
            
            # get the valid dates for this SVN
            $validFrom  = $self -> {atx}{$prn}{$svn}{"validFrom"};
            $validUntil = $self -> {atx}{$prn}{$svn}{"validUntil"};
            
            # check the dates
            if ($validFrom <= $date and $date <= $validUntil){
                
                # OK, add prn to the list
                push(@prnArray,$prn);
                
                # don't check other SVN 
                last;
            }
        }
    }
    
    return @prnArray;
}


1;
