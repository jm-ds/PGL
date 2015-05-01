use Carp;
use strict;
use warnings;

# import the parser
use PGL::Parsers::CMC;

# import OTL utils
use PGL::Utils::OTL;

# import fortran formatting module
use PGL::Fortran::Format;

# define the file to parse
my $cmcFile = "../DB/CMC/otl.cmc";

# initialize the parser with the cmc file 
my $cmcParser = new PGL::Parsers::CMC(file => $cmcFile);

# parse the cmc file
$cmcParser -> parse();

# print out a list of models in the CMC file
foreach my $model ( $cmcParser -> getModels() ){
    print "found model: ",$model,"\n";
}

# the model to use ...
my $model = "TPXO.5";
   $model = "CSR3.0_f";
   $model = "FES2004";
   $model = "GOT4.7";

# check if the model is defined
if ( $cmcParser -> exists( forModel => $model ) ){
    
    # let the user know we've found the station
    print "found model $model in CMC\n";
    
} else {
    
    # crap out
    confess("did not find model $model in CMC\n");
}

# get the OTL for this station (hash ref)
my $cmc = $cmcParser -> getCMC( forModel => $model);

# for to translate x --> 1, y --> 2, z --> 3
my %componentNumber = ("x", 1, "y", 2, "z", 3);

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
        
        # get the number associated with the component
        my $theComponentNumber = $componentNumber{$component};
        
        # get the Doodson number associated with the tidal species
        my $doodsonNumber 
            = PGL::Utils::OTL 
                -> getDoodsonNumberAsString( forSpecies => $tidalSpecies );
        
        # make the geodyn "A" and "B" OLOAD coefficents 
        my $A = $inPhase;
        my $B = $crossPhase;
        
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
                          $model  
                         ));  
    }   
}
