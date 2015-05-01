
use Carp;
use strict;
use warnings;

# import coordinate transformations
use PGL::Utils::Coordinate;

# import fortran formatting modula
use PGL::Fortran::Format;

# define format for printing coordinats
my $format = PGL::Fortran::Format -> new("3F15.4");

# cartesian coordinates of station YELL
my $xyz = [-1224452.452, -2689216.060,  5633638.312];
my $ref = [-1224462.452, -2689226.060,  5633628.312];

# convert this coordinate to lat, lon, and height (decimal degrees, meters)
my @xyz2llh = PGL::Utils::Coordinate 
    -> transform( $xyz, frm  => "xyz",       to => "llh");
 
my @xyz2sph = PGL::Utils::Coordinate
    -> transform( $xyz, from => "cartesian", to => "spherical" );

my @xyz2neu = PGL::Utils::Coordinate
    -> transform( $xyz, from => "cartesian", to => "neu", at => $ref);
    
# print the transformations
print( $format -> write(@{$xyz} ) );
print( $format -> write(@xyz2llh) );
print( $format -> write(@xyz2sph) );
print( $format -> write(@xyz2neu) );
print "\n";

# convert this coordinate to lat, lon, and height (decimal degrees, meters)
my @llh = PGL::Utils::Coordinate 
    -> transform( $xyz, frm  => "xyz",  to => "llh");
    
my @llh2xyz = PGL::Utils::Coordinate 
    -> transform( \@llh, frm  => "llh", to => "xyz");

my @llh2sph = PGL::Utils::Coordinate
    -> transform( \@llh, frm => "llh",  to => "sph",);
    
my @llh2neu = PGL::Utils::Coordinate
    -> transform( \@llh, frm => "llh",  to => "neu", at => $ref);
    
print( $format -> write(@llh    ) );
print( $format -> write(@llh2xyz) );
print( $format -> write(@llh2sph) );
print( $format -> write(@llh2neu) );
print "\n";

# convert this coordinate to lat, lon, and radius (decimal degrees, meters)
my @sph = PGL::Utils::Coordinate 
    -> transform( $xyz, frm  => "xyz", to => "sph");
    
my @sph2xyz = PGL::Utils::Coordinate 
    -> transform( \@sph, frm => "sph", to => "xyz");

my @sph2sph = PGL::Utils::Coordinate
    -> transform( \@sph, frm => "sph", to => "llh",);
    
my @sph2neu = PGL::Utils::Coordinate
    -> transform( \@sph, frm => "sph", to => "neu", at => $ref);
    
print( $format -> write(@sph    ) );
print( $format -> write(@sph2xyz) );
print( $format -> write(@sph2sph) );
print( $format -> write(@sph2neu) );
print "\n";

# convert this coordinate to north, east, up [m]
my @neu = PGL::Utils::Coordinate 
    -> transform(  $xyz, frm => "xyz", to => "local", at => $ref);
    
my @neu2xyz = PGL::Utils::Coordinate 
    -> transform( \@neu, frm => "neu", to => "xyz"  , at => $ref);

my @neu2llh = PGL::Utils::Coordinate
    -> transform( \@neu, frm => "neu", to => "llh"  , at => $ref);
    
my @neu2sph = PGL::Utils::Coordinate
    -> transform( \@neu, frm => "neu", to => "sph"  , at => $ref);
    
print( $format -> write(@sph    ) );
print( $format -> write(@sph2xyz) );
print( $format -> write(@sph2sph) );
print( $format -> write(@sph2neu) );
print "\n";
