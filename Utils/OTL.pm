package PGL::Utils::OTL;

use Carp;
use POSIX;
use strict;
use warnings;

sub __parseKwArgs{
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    my $species   = undef;
    my $year      = undef;
    my $fday      = undef;

    # parse the kwargs
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        if ($key =~ m/^species$/i or $key =~ m/^forspecies$/i){
            
            # make sure the value is upper case
            $species = uc($value);
            
        }elsif ($key =~ m/^day$/i 
                    or $key =~ m/^forDay$/i 
                        or $key =~ m/^andday$/i 
                            or $key =~ m/^onday$/i ){
            
            $fday = $value;
            
        }elsif ($key =~ m/^year$/i 
                    or $key =~ m/^foryear$/i 
                        or $key =~ m/^andyear$/i 
                            or $key =~ m/^onyear$/i){
            
            $year = $value;
            
        }else{
            # no clue what this is so yell at the user 
            carp("Unrecognized input key: $key, with value: $value\n");
        }
    }
    
    return ($species, $year, $fday);
    
}

sub getDoodsonNumberAsString{
    
    # get reference to this
    my $self = shift;
    
    # init var
    my ($species, $year, $fday)  = __parseKwArgs(@_);
    
    # define the doodson numbers for common tidal species
    # NOTE: I think N2 is wrong, but I want   
    #       to be consistent with GEODYN here
    #
    # NOTE: store as STRING here since 057555 does not compute
    my %doodsonNumbers = (
                          "M2" , "255555",
                          "S2" , "273555",
                          "N2" , "245555",
                          "K2" , "275555",
                          "K1" , "165555",
                          "O1" , "145555",
                          "P1" , "163555",
                          "Q1" , "135655",
                          "MF" , "075555",
                          "MM" , "065455",
                          "SSA", "057555"
                         );
    
    # check that the species is defined
    if ( defined $doodsonNumbers{ $species } ){
        
        # ok, its defined so give it up
        return $doodsonNumbers{ $species };
        
    } else {
        
        # no doodson number for this species 
        # this would happen by default but like
        # to code the undef return explicitly
        return undef;  
    }   
}

sub ARG2 {
    
    # get reference to package
    my $self = shift;
        
    # figure out which species user wants
    my ($species, $IYEAR, $DAY)  = __parseKwArgs(@_);
        
    # order of the tidalSpecies
    my @tidalSpecies = (
                        "M2","S2","N2","K2",
                        "K1","O1","P1","Q1",
                        "MF","MM","SSA"
                        );
    
    my $SIGM2   = 1.40519e-4;  
    my $SIGS2   = 1.45444e-4;  
    my $SIGN2   = 1.37880e-4; 
    my $SIGK2   = 1.45842e-4;
    my $SIGK1   = 0.72921e-4;  
    my $SIGO1   = 0.67598e-4;  
    my $SIGP1   = 0.72523e-4; 
    my $SIGQ1   = 0.64959e-4;
    my $SIGMf   = 0.053234e-4; 
    my $SIGMm   = 0.026392e-4; 
    my $SIGSsa  = 0.003982e-4;
    
    my @ANGFAC1 = ( 2.0,  0.0,  2.0,  2.0,  1.0,   1.0,  -1.0,   1.0,  0.0,  0.0,  2.0);     
    my @ANGFAC2 = (-2.0,  0.0, -3.0,  0.0,  0.0,  -2.0,   0.0,  -3.0,  2.0,  1.0,  0.0);     
    my @ANGFAC3 = ( 0.0,  0.0,  1.0,  0.0,  0.0,   0.0,   0.0,   1.0,  0.0, -1.0,  0.0);     
    my @ANGFAC4 = ( 0.0,  0.0,  0.0,  0.0,  0.25, -0.25, -0.25, -0.25, 0.0,  0.0,  0.0); 
    
    my @SPEED   = (                            
                   $SIGM2, $SIGS2, $SIGN2, $SIGK2, 
                   $SIGK1, $SIGO1, $SIGP1, $SIGQ1, 
                   $SIGMf, $SIGMm, $SIGSsa        
                  ); 
    
    my $ID      = floor($DAY)+0.0;            
    my $DTR     = 0.174532925199e-1;
    my $TWOPI   = 6.283185307179586476925287; 
    
    # Compute fractional part of day in seconds 
    my $FDAY    = ( $DAY - $ID ) * 86400.0;
    my $ICAPD   = ceil($ID + 365.0 * ( $IYEAR - 75.0 ) + ( ( $IYEAR - 73.0 ) / 4.0 ));
    my $CAPT    = ( 27392.500528 + 1.000000035 * $ICAPD ) / 36525.0;
    
    # Compute mean longitude of Sun at beginning of day
    my $H0 = ( 279.69668 + ( 36000.768930485 + 3.03e-4 * $CAPT ) * $CAPT ) * $DTR;

    # Compute mean longitude of Moon at beginning of day 
    my $S0 = ( ( ( 1.9e-6 * $CAPT - 0.001133 ) * $CAPT + 481267.88314137 ) * $CAPT + 270.434358 ) * $DTR;

    # Compute mean longitude of lunar perigee at beginning of day 
    my $P0 = ( ( ( -1.2e-5 * $CAPT -0.010325 ) * $CAPT + 4069.0340329577 ) * $CAPT + 334.329653 ) * $DTR; 
    
    # initialize the angles
    my @ANGLE;
    
    # calculate each angle one by one
    for (my $i = 0; $i < 11; $i++){

        $ANGLE[$i] = $SPEED  [$i] * $FDAY  
                   + $ANGFAC1[$i] * $H0    
                   + $ANGFAC2[$i] * $S0    
                   + $ANGFAC3[$i] * $P0    
                   + $ANGFAC4[$i] * $TWOPI;
         
        $ANGLE[$i] = fmod($ANGLE[$i],$TWOPI);
             
        if ($ANGLE[$i] < 0){ 
            $ANGLE[$i] = $ANGLE[$i] + $TWOPI;
        }
    }
    
    # initialize the output
    my %ARG;
    
    # assign each tidal species an angle
    @ARG{@tidalSpecies} = @ANGLE;
    
    # make sure the tidal species exists
    if ( defined $ARG{$species} ){
        
        # ok, return that angle
        return $ARG{$species};
        
    # otherwise
    }else {
        
        # nothing
        return undef;
    }
}


1;
