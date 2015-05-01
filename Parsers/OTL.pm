package PGL::Parsers::OTL;

=head1 NAME
 
  PGL::Parsers::OTL - Parse ocean tide loading (OTL) files in BLQ format
 
=head1 SYNOPSIS
 
    # import the parser
    use PGL::Parsers::OTL;
    
    # define the file to parse
    my $otlFile = "../DB/OTL/otl.fes2004.blq";
    
    # initialize the parser with the otl file 
    my $otlParser = new PGL::Parsers::OTL(file => $otlFile);
    
    # parse the otl file
    $otlParser -> parse();
 
=head1 DESCRIPTION

    The primary goal of this modual is to efficiently access
    ocean loading infomation stored in BLQ format.

    Below is an example of OTL information for SLR station POTS
    in the IERS standard BLQ format

     POTS_SLR      
    $$ FES2004_PP ID: 2012-01-04 02:12:23
    $$ Computed by OLMPP by H G Scherneck, Onsala Space Observatory, 2012
    $$ pots,                      RADI TANG  lon/lat:   13.0653   52.3803  147.848
     .00433 .00157 .00096 .00039 .00212 .00106 .00070 .00012 .00061 .00034 .00029
     .00176 .00045 .00039 .00012 .00041 .00033 .00014 .00006 .00007 .00004 .00004
     .00023 .00006 .00007 .00001 .00032 .00010 .00011 .00002 .00001 .00001 .00001
      -70.3  -37.0  -93.5  -47.3  -57.2 -100.3  -57.8 -151.7   12.3    8.4    1.5
       82.0  121.1   57.9  111.8   98.9   41.4   96.7   -3.7 -171.0 -169.5 -177.6
       73.8   41.9   78.4   15.1   40.3  -24.6   40.3 -145.6   60.0   60.6    2.7

    Here the column order is by tidal species
        
                    M2  S2  N2  K2  K1  O1  P1  Q1  MF  MM SSA
                    
    The row order is defined by amplitudes (meters) followed by phase (degrees)
    
                         U, W, S, phaseU, phaseW, phaseS
                    
    Typically for geodetic studies one works with local coordinate system East, 
    North, Up (ENU) system (not WSU) so it should be noted that
    
                                 -W    -->   E
                                 -S    -->   N 
                                  U    -->   U
                               phaseW  --> phaseE
                               phaseS  --> phaseN
                               phaseU  --> phaseU
                               
    Chapter 7.1.2 of the IERS 2010 standards:
    
          http://www.iers.org/IERS/EN/Publications/TechnicalNotes/tn36.html
    
Let ∆c denote a displacement component (radial, west, south) at a particular 
    site at time t. Then ∆c is obtained as
    
         sum (i = 1:3, j = 1:11) amplitude(i,j) * cos( X(j,t) - phase(i,j) )
            
    where the summation is carried out for a set of tidal constituents. The 
    amplitudes amplitude(i,j)  and  phases phase(i,j) describe the loading 
    response for the chosen site. The astronomical argument X(j,t) for the 
    11 main tides can be computed with the subroutine ARG2.F, which can be 
    obtained at 
    
                   ftp://tai.bipm.org/iers/conv2010/chapter7
                   
    A perl implementation of ARG2.F is provided by PGL::Utils::OTL -> ARG2
                               
    WHERE TO GET OTL:
    
        To generate OTL at any location using a variety of OTL models visit
        
                      http://froste.oso.chalmers.se/loading/
                      
        Step 1: Select ocean tide model, FES2004 for example.
        
        Step 2: Choose to apply center of mass correction (CMC)
        
                If you will use the PGL::Parser::CMC and apply CMC 
                then you would choose *not* to apply CMC at this stage
                
        Step 3: Decide if you'd like a plot (typically not)
        
        Step 4: Select output format BLQ
        
        Step 5: Input locations for up to 100 points as either:
            
                               TAG    X   Y  Z
                               TAG   lat lon ht
                        
                Example:
                
                     POTS_SLR  3800621.09 882005.50 5028859.62
                               
        Step 6: Enter the email address to receive the results
    
        Step 7: Ingest the results using PGL::Parsers::OTL
        
=head2 Functions
  
=head3 new

    Initialize the parser object:
    
    my $otlParser = new PGL::Parsers::OTL( file => "/some/path/file.otl");
  
=head3 parse

    Must call parse() before accessing OTL information.

    $otlParser -> parse();
    
=head3 exists

    Check if a certain tag/station exists in otl/blq file
    
    # set the station to look for
    my $stnName = "POTS_SLR";
    
    # check if some stations are defined in file
    if ( $otlParser -> exists( tag => $stnName ) ){
        
        # let the user know we've found the station
        print "found station $stnName in OTL\n";
        
    } else {
        
        # crap out
        confess("did not find station $stnName in OTL\n");
    }
    
=head3 getTags

    Return a list of tags/stns defined in the BLQ file
    
    foreach my $tag ( $otlParser -> getTags() ){
        print "found station: ",$tag,"\n";
    }
    
=head3 getOTL

    Access OTL as a hash ref for a given station or tag
    my $otl = $otlParser -> getOTL(forName => $stnName);
    
    # access the tidal coeffs etc
    foreach my $tidalSpecies (keys %{ $otl }){
    
    # short cut w/ hashref
    my $species = ${$otl}{$tidalSpecies};
    
    # loop over each component and print amplitude and phase
    foreach my $component (keys %{ $species }){
        
        # get the amplitude of the species component
        my $amp = ${$species}{$component}{'amplitude'};
        
        # get the phase of the species component
        my $phase = ${$species}{$component}{'phase'};
        
    AND SO ON ...
    
    
=head1 AUTHOR

    Abel Brown (brown.2179@gmail.com)
    
    01/02/2012
    
=head1 SEE ALSO

    Code:
        PGL::Utils::OTL
        PGL::Examples::OtlParserExample.pl
        PGL::Examples::OtlUtilsExample.pl
    
    IERS OTL loading:
        http://froste.oso.chalmers.se/loading/
        http://www.iers.org/IERS/EN/Publications/TechnicalNotes/tn36.html
    
    References:
        http://en.wikipedia.org/wiki/Arthur_Thomas_Doodson
        http://web.vims.edu/physical/research/TCTutorial/tideanalysis.htm
        http://oceanworld.tamu.edu/resources/ocng_textbook/chapter17/chapter17_04.htm
    
 
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
                 otl  => undef,
                 file => undef 
               };
      
    # parse keyword input arguments         
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        # make sure the key is lower case
        $key = lc($key);
        
        # look for a file keyword
        if ($key =~ /^file$/ || $key =~ /^otlfile$/){
            
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
    my $tag          = undef;
    my $data         = undef;
    my @tidalSpecies = ();
    my @splitLine    = ();
    
    my $indx         = 0;
    my $i            = undef;
    my @component    = ("u","w","s","u","w","s");
    my @dataType     = (
                        "amplitude","amplitude","amplitude",
                          "phase",    "phase",    "phase"
                       );
    
    # get reference to this
    my $self = shift;
    
    # open the BLQ file for reading
    my $fid = IO::File -> new($self -> {file},"r")
        or confess("Could not open file ",$self->{file},"\n");
        
    # loop over all the lines
    while ( defined ( $line = $fid -> getline() ) ){
        
        # remove white spaces and trailing new lines
        chomp($line);
        
        # OK, need to find the "COLUMN ORDER" line and parse tidal species
        @tidalSpecies = ($line =~ m/(\b\w{2,3}\b)/g) 
            if $line =~ m/column\s+order/i;
        
        # now check if comment line and move along if so
        next if $line !~ m/^\s/;
        
        # know its a data line now so break it up
        @splitLine = split(/\s+/,$line);
        
        # remove empty first entry
        shift @splitLine;
                
        # now need to find a "tag" line has only a single entry
        $tag  = shift(@splitLine) if scalar(@splitLine) == 1;
        
        # parse data lines
        if (scalar(@splitLine) == scalar(@tidalSpecies)){
            
            # compute circular index, 
            $i = $indx++ % 6;
            
            # store the data by tag, tidal species, data type, and component
            #
            # Note: access example:
            # 
            #               amp   = otl{'ALBH'}{'M2'}{'u'}{'amplitude'}
            #               phase = otl{'ALBH'}{'M2'}{'u'}{'phase'}
            #
            for (my $j = 0; $j < scalar(@tidalSpecies); $j++){
                $self -> {otl}{$tag}{$tidalSpecies[$j]}{$component[$i]}{$dataType[$i]} = $splitLine[$j];
            }
        } 
    }
}

sub __parseKwArgs{
    
    my $self = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    my $tag = undef;

    # parse the kwargs
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        # make sure the key is lower case
        $key  = lc($key);
        
        if ($key =~ /^tag$/ 
                or $key =~ /^withtag$/ 
                    or $key =~ /^fortag$/ 
                        or $key =~ /^havingtag$/
                            or $key =~ /^withname$/
                                or $key =~ /^forname$/
                                    or $key =~ /^name$/){
            $tag = $value;
            
        }else{
            # no clue what this is so yell at the user 
            carp("Unrecognized input key: $key, with value: $value\n");
        }
    }
    
    return $tag;
    
}

sub exists{
    
    # get reference to self
    my $self  = shift;
    
    # parse key word args
    my $tag = $self -> __parseKwArgs(@_);
    
    if (! defined $tag){
        confess("Must use tag key word argument as input the check existance\n");
    }
    
    return defined $self -> {otl}{$tag};
}

sub getTags{
    
    # get this
    my $self = shift;
    return keys %{$self -> {otl}}
}

sub getOTL {
    
    # get reference to self
    my $self = shift;
    
    # parse key-word args
    my $tag = $self -> __parseKwArgs(@_);
    
    # make sure tag is defined
    if (! defined $tag){
        confess("Must use tag key word argument as input the check existance\n");
    }
    
    if ( $self -> exists( tag => $tag ) ){
        return $self -> {otl}{$tag}
    } else {
        confess("The requested tag: $tag does not exist\n");
    }   
}
1;
