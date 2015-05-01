package PGL::Parsers::CMC;

=head1 NAME
 
  PGL::Parsers::CMC - Parse ocean tide loading (CMC) files
 
=head1 SYNOPSIS
 
    # import the parser
    use PGL::Parsers::CMC;
    
    # define the file to parse
    my $cmcFile = "../DB/CMC/otl.cmc";
    
    # initialize the parser with the cmc file 
    my $cmcParser = new PGL::Parsers::CMC(file => $cmcFile);
    
    # parse the cmc file
    $cmcParser -> parse();
 
=head1 DESCRIPTION

    The primary goal of this modual is to provide access to 
    CMC files provided by OSO/IERS
    
    Below is a standard CMC file for FES2004 provided by OSO at
    
            http://froste.oso.chalmers.se/loading/CMC/
    
  species     model            Zin         Zcr            Xin        Xcr            Yin        Ycr
    M2     NCDF_FES2004    -1.2661E-03 -1.4298E-03   -1.3724E-03  8.2077E-04    1.1479E-03  2.3005E-04
    S2     NCDF_FES2004    -1.7763E-04 -5.7273E-04   -5.3350E-04 -3.1591E-04   -5.1370E-05  2.8184E-04
    N2     NCDF_FES2004    -3.2372E-04 -2.8986E-04   -2.7121E-04  1.9849E-04    2.6018E-04 -1.4302E-04
    K2     NCDF_FES2004    -1.1814E-04 -1.5250E-04   -1.1223E-04 -1.0889E-05   -1.5751E-05  1.2367E-04
    K1     NCDF_FES2004    -1.1370E-03  4.4839E-03   -1.8539E-03 -8.6426E-04   -9.1022E-04 -1.7823E-03
    O1     NCDF_FES2004    -1.6802E-04  2.9702E-03   -1.3985E-03 -2.2975E-04   -8.8858E-04 -6.4989E-04
    P1     NCDF_FES2004    -3.6495E-04  1.4941E-03   -6.1436E-04 -2.9129E-04   -2.9261E-04 -5.7461E-04
    Q1     NCDF_FES2004     3.0709E-05  4.5472E-04   -2.7831E-04 -2.9313E-05   -2.1734E-04 -4.1637E-05
    Mf     NCDF_FES2004    -5.0643E-04 -7.3040E-05   -2.2065E-04  4.1472E-04   -1.0212E-04  8.2276E-05
    Mm     NCDF_FES2004    -2.7885E-04  2.0596E-05    4.6882E-05  1.8399E-04   -7.4897E-06  1.3209E-05
    Ssa    NCDF_FES2004    -1.4899E-04  2.6146E-06    1.3687E-04  3.5475E-05   -2.4093E-05  3.1666E-07
    
    The official Fortran format of the file is (a,1p,t42,3(2x,2e12.4))
    
    Chapter 7.1.2 of the IERS 2010 standards:
    
          http://www.iers.org/IERS/EN/Publications/TechnicalNotes/tn36.html
       
    If necessary, the crust-frame translation (geocenter motion) due 
    to the ocean tidal mass, dX(t), dY (t), and dZ(t), may be computed 
    according to the method given for dX(t) as
    
        dX(t) = sum( j = 1:11 ) Xin(j) * cos( X(j,t) ) + Xcr(j) * sin( X(j,t) )
            
    where the in-phase (in) and cross-phase (cr) amplitudes (in meters) 
    are tabulated for the various ocean models. Similarly for dY(t) and dZ(t). 
    This correction should be applied, for instance, in the transformation 
    of GPS orbits from the center-of-mass to the crust-fixed frame expected 
    in the sp3 orbit format

                          Xcrust-fixed = Xcenter-of-mass - dX
    
    i.e. the translation vector should be substracted when going from center-of-mass to sp3.
    
    NOTE:  the astronomical argument, X(j,t), at time t for each of the tidal species
           is computed by ARG2.F.  A perl implementation of this function is provided 
           by PGL::Utils::OTL
        
        
=head2 Functions
  
=head3 new

    Initialize the parser object:
    
    my $cmcParser = new PGL::Parsers::CMC( file => "/some/path/file.cmc");
  
=head3 parse

    Must call parse() before accessing CMC information.

    $cmcParser -> parse();
    
=head3 exists

    Check if a certain model exists in cmc file
    
    # set the station to look for
    my $model = "FES2004";
    
    # check if some stations are defined in file
    if ( $cmcParser -> exists( model => $model ) ){
        
        # let the user know we've found the station
        print "found model $model in CMC\n";
        
    } else {
        
        # crap out
        confess("did not find model $stnName in CMC\n");
    }
    
=head3 getModels

    Return a list of tags/stns defined in the BLQ file
    
    foreach my $model ( $cmcParser -> getModels() ){
        print "found model: ",$model,"\n";
    }
    
=head3 getCMC

    Access CMC as a hash ref for a given station or tag
    my $cmc = $cmcParser -> getCMC(forModel => $model);
    
    # access the tidal coeffs etc
    foreach my $tidalSpecies (keys %{ $cmc }){
    
        # short cut w/ hashref
        my $species = ${$cmc}{$tidalSpecies};
        
        # loop over each component and print amplitude and phase
        foreach my $component (keys %{ $species }){
            
            # get the inphase component of the species component
            my $inPhase    = ${$species}{$component}{'inphase'};
            
            # get the cross phase of the species component
            my $crossPhase = ${$species}{$component}{'crossphase'};
        
    AND SO ON ...

=head1 AUTHOR

    Abel Brown (brown.2179@gmail.com)
    
    01/04/2012
    
=head1 SEE ALSO

    Code:
        PGL::Utils::OTL
        PGL::Examples::OtlParserExample.pl
        PGL::Examples::OtlUtilsExample.pl
    
    IERS OTL loading:
        http://froste.oso.chalmers.se/loading/
        http://froste.oso.chalmers.se/loading/CMC/
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

sub new {
    
    # get the class name
    my $class = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    # initialize self hash
    my $self = { 
                 cmc   => undef,
                 file  => undef,
               };
      
    # parse keyword input arguments         
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        # make sure the key is lower case
        $key = lc($key);
        
        # look for a file keyword
        if ($key =~ /^file$/ || $key =~ /^cmcfile$/){
            
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
    
    # get reference to this
    my $self = shift;
    
    # NOTE: use IO::File for readability
    
    # init variable for holding current line
    my $line = undef;
    
    # init parsing variables
    my $tag          = undef;
    my $data         = undef;
    my $tidalSpecies = undef;
    my $model        = undef;
    my @splitLine    = ();
    
    my $indx         = 0;
    my $i            = undef;
    my @component    = ("z","z","x","x","y","y");
    my @dataType     = (
                         "inphase", "crossphase",    
                         "inphase", "crossphase", 
                         "inphase", "crossphase"
                       );
    
    # open the BLQ file for reading
    my $fid = IO::File -> new($self -> {file},"r")
        or confess("Could not open file ",$self->{file},"\n");
        
    # loop over all the lines
    while ( defined ( $line = $fid -> getline() ) ){
        
        # remove white spaces and trailing new lines
        chomp($line);
        
        # valid data line has 8 entries 
        @splitLine = split(/\s+/,$line);
        
        # move along if not
        next if scalar(@splitLine) != 8;
                
        $tidalSpecies = $splitLine[0];
        $model        = $splitLine[1];
        
        # parse out model name
        $model =~ s/NCDF_//g;
        
        for (my $j = 0; $j < 6; $j++){
            
            # compute circular index, 
            $i = $indx++ % 6;
            
            # store the data
            #
            # Note: access example:
            # 
            #         inPhaseZ = cmc{'M2'}{'z'}{'inphase'}
            #      crossPhaseZ = cmc{'M2'}{'z'}{'crossphase'}
            #
            $self -> {cmc}{    $model      }
                          { $tidalSpecies  }
                          { $component[$i] }
                          { $dataType [$i] } = $splitLine[2+$j];
              
        }
    }
}

sub __parseKwArgs{
    
    my $self = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    my $model = undef;

    # parse the kwargs
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        # make sure the key is lower case
        $key  = lc($key);
        
        if ($key =~ /^model$/  
                    or $key =~ /^formodel$/ ){
            $model = $value;
            
        }else{
            # no clue what this is so yell at the user 
            carp("Unrecognized input key: $key, with value: $value\n");
        }
    }
    
    return $model;   
}

sub exists{
    
    # get reference to self
    my $self  = shift;
    
    # parse key word args
    my $model = $self -> __parseKwArgs(@_);
    
    if (! defined $model){
        confess("Must use model key word argument as input the check existance\n");
    }
    
    return defined $self -> {cmc}{$model};
}

sub getModels{
    
    # get this
    my $self = shift;
    return keys %{$self -> {cmc}}
}

sub getCMC {
    
    # get reference to self
    my $self = shift;
    
    # parse key-word args
    my $model = $self -> __parseKwArgs(@_);
    
    # make sure model is defined
    if (! defined $model){
        confess("Must use model key word argument as input the check existance\n");
    }
    
    if ( $self -> exists( model => $model ) ){
        return $self -> {cmc}{$model}
    } else {
        confess("The requested model: $model does not exist\n");
    }   
}

1;
