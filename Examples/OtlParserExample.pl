use Carp;
use strict;
use warnings;
use Math::Trig;

# import the parser
use PGL::Parsers::OTL;

# import the OTL utils
use PGL::Utils::OTL;

# import fortran formatting module
use PGL::Fortran::Format;

# define the file to parse
my $otlFile = "../DB/OTL/otl.fes2004.blq";

# initialize the parser with the otl file 
my $otlParser = new PGL::Parsers::OTL(file => $otlFile);

# parse the otl file
$otlParser -> parse();

# print out list of tags/stations in the BLQ file
#foreach my $tag ( $otlParser -> getTags() ){
#    print "found station: ",$tag,"\n";
#}

# print number of tags found in the file
print "found ",scalar($otlParser -> getTags())," tags in BLQ file\n";

# set the station to look for
my $stnName = "TROM";

# check if some stations are defined in file
if ( $otlParser -> exists( tag => $stnName ) ){
    
    # let the user know we've found the station
    print "found station $stnName in OTL\n";
    
} else {
    
    # crap out
    confess("did not find station $stnName in OTL\n");
}

# get the OTL for this station (hash ref)
my $otl = $otlParser -> getOTL(forName => $stnName);

# for to translate w -> e, s -> n
my %translateComponent = ("w", "e", "s", "n");

# for to translate e --> 1, n --> 2, u --> 3
my %componentNumber = ("e", 1, "n", 2, "u", 3);

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
        
        # convert west and south to east and north
        if ( $component =~ m/^w$/i or $component =~ m/^s$/i){
            
            # reverse the sign of the amplitue
            $amp = -1.0 * $amp;
            
            # component symbol w -> e and  s -> n
            $component = $translateComponent{$component};
        }
        
        # get the number associated with the component
        my $theComponentNumber = $componentNumber{$component};
        
        # get the Doodson number associated with the tidal species
        my $doodsonNumber 
            = PGL::Utils::OTL 
                -> getDoodsonNumberAsString( forSpecies => $tidalSpecies );
        
        # make the geodyn "A" and "B" OLOAD coefficents 
        my $A = $amp * cos( deg2rad( $phase ) );
        my $B = $amp * sin( deg2rad( $phase ) );
        
        # print out the A and B in geodyn OLOAD format
        print PGL::Fortran::Format 
            -> new("A5,A,I2,A,A6,A,D13.6,A,D13.6,A,A3,A,A1,A,A") 
                -> write((
                          "OLOAD",            " ",
                          $theComponentNumber," ",
                          $doodsonNumber,     " ",
                          $A,                 " ",
                          $B,                 " ",
                          $tidalSpecies,      " ",
                          $component,         " ",
                          $stnName  
                         ));  
    }   
}
