
use Carp;
use POSIX;
use strict;
use warnings;

# import otl utils
use PGL::Utils::OTL;

## test ARG2.f using the example given
#*  Test case:
#*     given input: IYEAR = 08 (2008)
#*                  DAY = 311.5 (November 6 Noon)
#*     expected output: ANGLE(1)  = 0.5785483804494191418D0 rad
#*                      ANGLE(2)  = 6.28318080000000023D0   rad
#*                      ANGLE(3)  = 5.897950576134803669D0  rad
#*                      ANGLE(4)  = 1.615958909210931438D0  rad
#*                      ANGLE(5)  = 2.378775781400364053D0  rad
#*                      ANGLE(6)  = 4.482957906228527634D0  rad
#*                      ANGLE(7)  = 3.904405018599632626D0  rad
#*                      ANGLE(8)  = 3.519174794734325928D0  rad
#*                      ANGLE(9)  = 1.037427808761705705D0  rad
#*                      ANGLE(10) = 0.9637917514941207742D0 rad
#*                      ANGLE(11) = 1.615972056390525324D0  rad

# order of the tidalSpecies
my @tidalSpecies = (
                    "M2","S2","N2","K2",
                    "K1","O1","P1","Q1",
                    "MF","MM","SSA"
                    );

# for each of the tidal species                    
foreach my $species (@tidalSpecies){
    
    # compute the astronommical argument
    my $astronomicalArgument 
        = PGL::Utils::OTL 
            -> ARG2(
                    forSpecies => $species, 
                    onYear     => 8, 
                    andDay     => 311.5
                   );
      
    # blab about it             
    printf("%3s, %10.7f\n", $species,$astronomicalArgument);
}
