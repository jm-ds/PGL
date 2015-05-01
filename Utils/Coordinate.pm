package PGL::Utils::Coordinate;

=head1 NAME
 
  PGL::Utils::Coordinate - Encapsulate the geodetic coordinate transformations 
 
=head1 SYNOPSIS
 
    # import coordinate transformations
    use PGL::Utils::Coordinate;
    
    # cartesian coordinates of GPS station YELL
    my $xyz = [-1224452.452, -2689216.060,  5633638.312];
    
    # a slightly perturbed coordinate to serve as reference position
    my $ref = [-1224462.452, -2689226.060,  5633628.312];
    
    my @xyz2llh = PGL::Utils::Coordinate 
        -> transform( $xyz, frm  => "xyz",       to => "llh");
     
    my @xyz2sph = PGL::Utils::Coordinate
        -> transform( $xyz, from => "cartesian", to => "spherical" );
    
    my @xyz2neu = PGL::Utils::Coordinate
        -> transform( $xyz, from => "cartesian", to => "neu", at => $ref);

   
    XYZ: -1224452.4520  -2689216.0600   5633638.3120
    LLH:       62.4809      -114.4807       180.8582
    SPH:       62.3229      -114.4807   6361528.7043
    NEU:       16.3743         4.9571   6361528.7042


=head1 DESCRIPTION

    This modual serves to transform coordinates between systems:
        
        1. X, Y, Z          (cartesian)
        2. lat, lon, height (ellipsoidal)
        3. lat, lon, radius (spherical)
        4. N, E, U          (local)
        
    All transformations between these systems are preformed throught 
    the "Coordinate -> transform" function as shown in the SYNOPSIS section.
    
    Unless otherwise stated, all units are meters and decimal degrees.

=head2 Functions

=head3 transform

    The heart of the module.  The first parameter is always an array reference
    to a 3-element array of coordinates.  The "from=>" and "to=>" key-words specify 
    the originating and destination systems. If a local coordinate system is used  
    the reference position is provided by the key-word " at => "
    
    Valid "from =>" and "to =>" key-words:
    
                    'x', 'xyz', 'cart' , 'cartisian'  , 'cartesian',
                    'e', 'llh', 'ell'  , 'ellipsoidal',
                    'g', 'llr', 'sph'  , 'spherical'  ,
                    'n', 'neu', 'local'
                    
    NOTE: the reference position for local coordinate systems provided
          by the "at=>" key-word must always be specifed in cartesian XYZ
          
    The output is a 3-element array (not a reference) of coordinates in the system 
    specified by the key-word "to=>"
    
=head1 AUTHOR

    Abel Brown (brown.2179@gmail.com)
    
    01/10/2012
    
=head1 SEE ALSO

    Code:
        PGL::Utils::CoordinatExample.pl
    
    References:
        Introduction to Geometrical and Physical Geodesy - Foundations of Geomatics
            Author:    Thomas H. Meyer
            ISBN:      978-1-58948-215-9
            Publisher: ESRI Press 
     
=cut

use Carp;
use POSIX;
use strict;
use warnings;
use Math::Trig;

# global (?)
my $dr = pi/180.0;

# Flattening according to WGS-84 
my $f = 1.0/298.257223563;  

# WGS-84 equatorial radius [m]  
my $a = 6378137.0;

sub _x2e{
    
    # Converts global cartesian coordinates into  ellipsoidal (geodetic)
    # input:  x,y,z in meters
    # output: lat, lon, height in decimal degrees
    my $coord = shift;
    
    # make sure input is valid size
    if ( scalar( @{$coord} ) != 3 ){
        confess("_x2e expects array of exactly 3 elements\n");  
    }
    
    # extract the coordinate from input
    my ($x,$y,$z) = (@{$coord}[0], @{$coord}[1], @{$coord}[2]);
        
    # 2x machine presision
    my $eps = 2.0 * DBL_EPSILON;
    
    # convergence parameter
    my $tol = 2.0 * $eps;
    
    # max number of iterations
    my $itmax = 10; 
    
    # Flattening in WGS-84
    #my $f = 1.0/298.257223563; 
    
    # WGS-84 equatorial radius in meters
    #my $a = 6378137.0;  
    
    my $esq = 2.0 * $f - $f * $f;
       
    my $p = sqrt($x**2 + $y**2); 
    
    # compute first approximation for lat
    my $lat= atan2($z / (1.0 - $esq),$p);
      
    #old lat   
    my $olat = $lat;
    
    #iteration number
    my $it = 0; 
    
    #inital difference
    my $diff = 2.0*$tol;
    
    my ($N, $h);

    #start iterative process
    while ($diff > $tol and $it < $itmax){
               
        $N = $a / sqrt( 1. - $esq * sin( $lat )**2);
        
        $h = $p / cos( $lat ) - $N;                      
        
        $lat = atan2( $z, $p * (1. - $esq * $N /($N + $h) ) );  
        
        $diff = abs( $lat - $olat ); 
         
        $olat = $lat;
        
        $it = $it + 1;
    }
        
    #assign longitude    
    my $lon = atan2($y,$x);    

    #check convergence
    if ($it >= $itmax){
        carp("transform from xyz to lat lon ht did not converge\n");
    }
        
    # assign return list
    return ( $lat * (1.0/$dr), $lon * (1.0/$dr), $h );
}

sub _e2x{
        
    # convert ellipsoidal (geodetic) coordinates to global cartesian coordinates
    # input: lat,lon,height in decimal degrees
    # output: x,y,z in meters
    
    # get the coordinate
    my $coord = shift;
    
    # make sure input is valid size
    if ( scalar( @{$coord} ) != 3 ){
        confess("_e2x expects array of exactly 3 elements\n");  
    }
    
    # extract the coordinate from input
    my ($lat,$lon,$ht) = (@{$coord}[0], @{$coord}[1], @{$coord}[2]);
    
    # convert to radians
    $lat = $lat * $dr;
    $lon = $lon * $dr;
    
    my $esq = 2.0 * $f - $f**2; 
     
    my $slat = sin($lat); my $clat = cos($lat); 
    my $slon = sin($lon); my $clon = cos($lon);
    
    # radius of curvature in prime vertical
    my $N = $a/sqrt( 1.0 - $esq * $slat**2 );  
    
    # do it
    my $x = ($N + $ht) * $clat * $clon;
    my $y = ($N + $ht) * $clat * $slon;
    my $z = ( (1.- $esq) * $N + $ht) * $slat;
    
    # that's a [w]rap
    return ($x,$y,$z);   
}

sub _x2g{

    # transform xyz from cartesian coordinates to spherical coordinates lat,lon,r
    # 
    # input: x,y,z in meters 3 x M
    # output: lat,lon,ht in degrees,degrees,meters
    #
    
    # get the coordinate
    my $coord = shift;
    
    # make sure input is valid size
    if ( scalar( @{$coord} ) != 3 ){
        confess("_x2g expects array of exactly 3 elements\n");  
    }
    
    # extract the coordinate from input
    my ($x,$y,$z) = (@{$coord}[0], @{$coord}[1], @{$coord}[2]);
    
    my $lat = atan2($z,sqrt($x**2 + $y**2));
    my $lon = atan2($y,$x);
    my $ht  = sqrt($x**2 + $y**2 + $z**2);
    
    return ($lat*(1.0/$dr),$lon*(1.0/$dr),$ht);   
}

sub _g2x{
    
    # transform spherical lat,lon,r geographical  
    # coordinates to global cartesian xyz coordinates
    # 
    # input:  lat,lon,r in deg,deg,meters
    # output: x,y,z in meters
    
    # get the coordinate
    my $coord = shift;
    
    # make sure input is valid size
    if ( scalar( @{$coord} ) != 3 ){
        confess("_g2x expects array of exactly 3 elements\n");  
    }
    
    # extract the coordinate from input
    my ($lat,$lon,$r) = (@{$coord}[0], @{$coord}[1], @{$coord}[2]);
    
    # convert to radians
    $lat = $lat * $dr; 
    $lon = $lon * $dr;
    
    my $sla = sin($lat);  my $cla = cos($lat); 
    my $slo = sin($lon);  my $clo = cos($lon);

    my $x = $r * $cla * $clo; 
    my $y = $r * $cla * $slo; 
    my $z = $r * $sla;

    return ($x,$y,$z);
}

sub _x2n{
    
    # get the coordinate
    my $coord = shift;
    
    # get the reference point
    my $ref   = shift;
    
    # make sure input is valid size
    if ( scalar( @{$coord} ) != 3 or scalar( @{$ref}) != 3 ){
        confess("_x2n expects 2 array references of exactly 3 elements\n");  
    }
    
    # extract the coordinate from input
    my ($x,$y,$z) = (@{$coord}[0], @{$coord}[1], @{$coord}[2]);

    # convert the reference position to spherical
    my @ref = _x2g($ref);
    
    my $sla = sin($ref[0]*$dr); my $slo = sin($ref[1]*$dr); 
    my $cla = cos($ref[0]*$dr); my $clo = cos($ref[1]*$dr);
    
    # would normally just use matrix multiplication here
    my $n = ( -$sla * $clo ) * $x + ( -$sla * $slo ) * $y + ( $cla  ) * $z;
    my $e = ( -$slo        ) * $x + (  $clo        ) * $y + ( 0.0   ) * $z;
    my $u = ( -$cla * $clo ) * $x + ( -$cla * $slo ) * $y + ( -$sla ) * $z;
                  
    return ($n,$e,-$u);
}

sub _n2x{
    
    # get the coordinate
    my $coord = shift;
    
    # get the reference point
    my $ref = shift;
    
    # make sure input is valid size
    if ( scalar( @{$coord} ) != 3 or scalar( @{$ref}) != 3 ){
        confess("_n2x expects 2 array references of exactly 3 elements\n");  
    }
    
    # extract the coordinate from input
    my ($n,$e,$u) = (@{$coord}[0], @{$coord}[1], @{$coord}[2]);

    # convert the reference position xyz to spherical
    my @ref = _x2g($ref);
    
    my $sla = sin($ref[0]*$dr); my $slo = sin($ref[1]*$dr); 
    my $cla = cos($ref[0]*$dr); my $clo = cos($ref[1]*$dr);
    
    # would normally just use matrix multiplication here
    my $x = ( -$sla * $clo ) * $n + ( -$slo        ) * $e + ( -$cla * $clo ) * $u;
    my $y = ( -$sla * $slo ) * $n + (  $clo        ) * $e + ( -$cla * $slo ) * $u;
    my $z = (  $cla        ) * $n + (  0.0         ) * $e + ( -$sla        ) * $u;
                  
    return ($x,$y,$z);
}

sub _isIn{
    
    # NOTE: using grep here for cross platform compatability
    #
    # would like to use List::MoreUtils
    # 
    #   return any { $_ eq $key} @{$array_ref};
    #
    # but not standard on SunOS systems for example
    #
    #
    my $key       = shift;
    my $array_ref = shift;   
    my @matches   = grep /$key/,@{$array_ref} ;
    return scalar(@matches);
}

sub transform{
    
    # parse the args
    my $pkgName = shift;
    
    # get the coordinate to transform
    my $coord = shift;
        
    # get the rest of the input args as keywords
    my (%kwargs) = @_;
 
    my $cartesian   = [ 'x', 'xyz', 'cart', 'cartisian', 'cartesian' ];
    my $ellipsoidal = [ 'e', 'llh', 'ell' , 'ellipsoidal'];
    my $spherical   = [ 'g', 'llr', 'sph' , 'spherical'  ];
    my $local       = [ 'n', 'neu', 'local'              ];
    
    my $validSrc = [
                    'x', 'xyz', 'cart' , 'cartisian'  , 'cartesian',
                    'e', 'llh', 'ell'  , 'ellipsoidal',
                    'g', 'llr', 'sph'  , 'spherical'  ,
                    'n', 'neu', 'local'
                   ];
                    
    my $validDst = [
                    'x', 'xyz', 'cart' , 'cartisian'  , 'cartesian', 
                    'e', 'llh', 'ell'  , 'ellipsoidal',
                    'g', 'llr', 'sph'  , 'spherical'  ,
                    'n', 'neu', 'local'
                   ];
    
    my $src = undef; 
    my $dst = undef; 
    my $ref = undef;
    
    # ok, parse those kwargs to get src, dst, and reference point
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        if ($key =~ m/^frm$/i or $key =~ m/^from$/i){
            
            # make sure that $value is actually a valid source
            if ( _isIn( $value, $validSrc ) ){
                $src = $value;
            }else{
                # yell at the user about it 
                confess("Unrecognized coordinate system: $value used in keyword arg: from= \n");  
            }
            
        }elsif ($key =~ m/^to$/i){
            
            # make sure that $value is proper system
            if ( _isIn( $value, $validDst ) ){
                $dst = $value;
            }else{
                # yell about it and explode
                confess("Unrecognized coordinate system: $value used in keyword arg: to= \n");  
            }
            
        } elsif ( $key =~ m/^at$/i ){
            
            # set the XYZ reference position
            $ref = $value;
        
        } else {
            
            # no clue what this is so yell at the user 
            carp("Unrecognized input key: $key, with value: $value\n");
        }
    }
    
#    print "@{$coord}\n";
#    print "src: $src, dst: $dst \n";
    
    # now make sure we have what we need to proceed
    if (! defined $dst or ! defined $src ){
        confess("Must define both frm= and to= for to apply transformation\n");
    }
    
    # make sure that reference point is defined for a local xformation
    if ( ( _isIn( $src, $local ) or _isIn( $dst, $local ) ) and ! defined $ref ){
        confess("Must provide reference location for local transformation using at= keyword argument\n");
    }
    
    # make sure the input coordinate is of 3 elements
    if (scalar(@{$coord}) != 3){
        confess("Coordinate for transformation must have 3 components\n");
    }
    
    #the transformed coordinate
    my @xCoord = undef; my @tmpCoord = ();
    
    if ( _isIn( $src, $cartesian )  and _isIn( $dst, $ellipsoidal ) ){
        
        return _x2e($coord);
        
    } elsif ( _isIn( $src, $cartesian) and _isIn( $dst, $spherical ) ){
        
        return _x2g($coord);
        
    } elsif( _isIn( $src, $cartesian ) and _isIn( $dst, $local) ){
        
        return _x2n($coord,$ref);
    
    } elsif ( _isIn( $src, $ellipsoidal )  and _isIn( $dst, $cartesian ) ){
    
        return _e2x($coord);
          
    } elsif ( _isIn( $src, $ellipsoidal )  and _isIn( $dst, $local ) ){
        
        @tmpCoord = _e2x($coord); return _x2n(\@tmpCoord,$ref);
        
    } elsif ( _isIn( $src, $ellipsoidal )  and _isIn( $dst, $spherical ) ){
        
        @tmpCoord = _e2x($coord); return _x2g(\@tmpCoord);
        
    } elsif ( _isIn( $src, $local )  and _isIn( $dst, $cartesian ) ){
        
        return _n2x( $coord, $ref );  
        
    } elsif ( _isIn( $src, $local )  and _isIn( $dst, $ellipsoidal ) ){
        
        @tmpCoord = _n2x($coord, $ref ); return _x2e(\@tmpCoord);  
        
    } elsif ( _isIn( $src, $local )  and _isIn( $dst, $spherical ) ){
        
        @tmpCoord = _n2x( $coord, $ref ); return _x2g(\@tmpCoord);
    
    } elsif ( _isIn( $src, $spherical )  and _isIn( $dst, $cartesian ) ){
     
        return _g2x($coord);   
    
    } elsif ( _isIn( $src, $spherical )  and _isIn( $dst, $ellipsoidal ) ){
        
        @tmpCoord = _g2x($coord); return _x2e(\@tmpCoord);
          
    } elsif ( _isIn( $src, $spherical )  and _isIn( $dst, $local ) ) {
        
        @tmpCoord = _g2x($coord); return _x2n(\@tmpCoord,$ref);
    
    } else {
        
        confess("transformation src: $src and dst: $dst combination is not valid\n")   
    }
    
}

1;
