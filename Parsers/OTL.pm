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
    
