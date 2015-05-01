package PGL::FTP::RemoteDataSrc;

=head1 NAME
 
  PGL::FTP::RemoteDataSrc - Mechanism for retreiving data files 
                            organized by date on FTP servers
 
=head1 SYNOPSIS
 
    use strict;
    use warnings;
    
    use PGL::Utils::Date;
    use PGL::FTP::RemoteDataSrc;
    
    # initialize a data source
    # Notice here that user and password default to "anonymous" 
    # FTP server connection is established upon creation!
    my $src = new RemoteDataSrc(
                                host  => "cddis.gsfc.nasa.gov",
                                path  => "/gps/data/daily/yyyy/doy/yyd/#key#doy0.yyd.Z",
                                debug => 0
                               );
                               
    # overloaded stringify                           
    print $src,"\n";
                             
    # initialize some start date
    my $startDate = new Date(gpsWeek=> 1042, gpsWeekDay => 2);
    
    # get 10 days worth of files for station zwen from CDDIS server
    for (my $date = $startDate; $date<= $startDate+100; $date++){
        $src -> aquire( localDst => "./data", withKey  => "zwen", forDate  => $date );
    }
    
    # all done
    $src->close();
 
=head1 DESCRIPTION
 
  Typically GSP data files are loacated on remote servers and 
  organized in daily and or yearly directories.  
  
  This object was created specifically for rnx, sp3, and nav file
  retreival but can easliy be used for any other type of file.
  
  The data source object is initialized with the FTP server login 
  information HOST, USER, and PASSWORD.  Note that user and password
  will default to anonymous.  The FTP connection is established upon
  object creation and needs to be explicitly closed as shown in the 
  example above.  Also DEBUG can be passed and set TRUE if the user
  would like to see all the chatter from the server and Net::FTP.
  
  The final required peice of information is the path for the data file.  
  This path can have generic definition such as
  
    /gps/data/daily/year/doy/yyd/#key#doy0.yyd.Z
 
  for GPS rinex on data server CDDIS. 
  
  For date 2001, 345, with key "albh" this generic path definition 
  translates to 
  
    /gps/data/daily/2001/345/01d/albh3450.01d.Z
    
  Likewise, SP3 files are located generically at 
  
    /gps/products/gpsweek/repro1/$key$gpsdate.sp3.Z
    
  which forDate 11/2/2003, withKey "ig1" translates to 
  
    /gps/products/1243/repro1/ig112430.sp3.Z
    
  Notice here that gpsdate is translated into 12430 where
  the GPS week is 1243 and the day of week is 0.
  
  
=head2 Functions

  There are only a few functions here as everything else is encapsulated.
  
=head3 aquire
 
      ($status,$msg) = $src -> aquire( 
                                       localDst => "./data", 
                                       withKey  => "zwen", 
                                       forDate  => $date 
                                      );
 
  a staus of undef if error encountered and 
  the message from the ftp server regarding the transaction.  
  
  All three keyword arguments are required.
  
=head3 close

    $src -> close();
    
    Closes connection to the FTP server.  
    
    The connection to the FTP server is created upon initialization and kept open
    indefinatly to facilitate multiple file xfers.  So be nice and explicitly close 
    the connection when you're done.
  
=head1 AUTHOR

    Abel Brown (brown.2179@gmail.com)
    
=head1 SEE ALSO

    PGL::Utils::Date
    PGL::Utils::DKResolve
 
=cut

use Carp;
use strict;
use warnings;
use Net::FTP;
use File::Spec;
use File::Basename;
use PGL::Utils::DKResolve;

use overload ('""' => \&stringify);

# accessors
sub host     { return shift -> {_host};     }
sub user     { return shift -> {_user};     }
sub password { return shift -> {_password}; }
sub path     { return shift -> {_path};     }

sub new {
    
    # get the class name
    my $class = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    # initialize self hash
    my $self = { 
        _host        => undef,
        _user        => undef,
        _password    => undef,
        _path        => undef,
        _ftp         => undef,
        _shouldDebug => undef
    };
    
    # debug control
    my $shouldDebug = 0;
    
    # parse the kwargs
    while ( my ($key, $value) =  each(%kwargs) ) {
        
        # make sure the key is lower case
        $key = lc($key);
        
        if ($key =~ /^host$/){
            
            $self->{_host} = $value;
            
        } elsif ($key =~ /^user$/){
            
            $self->{_user} = $value;
            
        } elsif ($key =~ /^password$/){
            
            $self->{_password} =$value;
            
        } elsif ($key =~ /^path$/){
            
            $self->{_path} = $value;
            
        } elsif ($key =~ /^debug$/){
            
            $self->{_shouldDebug} = $value;
            
        } else {
            
            # no clue what this is so yell at the user 
            carp("Unrecognized input key: $key, with value: $value\n");
        }
    }
    
    # make sure that the host is specified otherwiese nothing to connect to
    if ( ! defined( $self->{_host} ) ){
        confess("Host not spcified.  Must input server addres using host keyword.  See documentaion.\n");
    }
    
    if ( ! defined( $self->{_path} ) ){
        confess("Remote file path is not defined.  Must input path to remote file using path keyword.  See documentation.\n");
    }
    
    # enforce some default values here
    if ( ! defined( $self->{_user} ) )     { $self->{_user}     = "anonymous"; }
    if ( ! defined( $self->{_password} ) ) { $self->{_password} = "anonymous"; }
    
    # init FTP connection
    $self->{_ftp} = Net::FTP->new($self->{_host}, Debug => $self->{_shouldDebug})
      or confess("Could not connect to server ", $self->{_host},"\n");
      
    # login to the server
    $self->{_ftp}->login($self->{_user},$self->{_password})
      or confess("Cannot login to server ", $self->{_host},": ", $self->{_ftp}->message);
    
    # and we're live! ... thats all folks
    return bless($self,$class);
}

sub aquire{
    
    # download the file to local file system 
    my $dst     = undef;
    my $date    = undef;
    my $keyWord = undef;
    my $src     = undef;
    
    
    # get reference to self/this
    my $self = shift;
    
    # get the input keyword args
    my (%kwargs) = @_;
    
    # parse those key word args
    while ( my ($key,$value) = each(%kwargs) ){
        
        # make sure key is lower case
        $key = lc($key);
        
        #|| $key =~ /^dest$/ || $key =~ /^localdest$/ || $key =~ /todest/ || $key =~ /^destination$/ || $key =~ /^at$/
        
        # get the local destination
        if ( $key =~ /^dst$/ || $key =~ /^localdst$/ || $key =~ /^todst$/ 
            || $key =~ /^dest$/ || $key =~ /^localdest$/ || $key =~ /todest/ 
                || $key =~ /^destination$/ || $key =~ /^at$/){
                    
            if (! -d $value){
                confess("$value is not a directory on the local file system.\n");
            }
            
            $dst = $value;         
                
        } elsif ( $key =~ /^date$/ || $key =~ /^fordate$/ || $key =~ /^withdate$/){
                        
            # make sure that input is actually a date object
            if ( $value -> isa("PGL::Utils::Date") ){ 
                $date = $value; 
            } else {
                # yell at the user 
                confess("date keyword value must be a date object\n");
            }
            
        } elsif ( $key =~ /^key$/ || $key =~ /^withkey$/ || $key =~ /^forkey$/){
            $keyWord = $value;
        }
        
    }
    
    # make sure we have what we need
    if ( ! defined($date) || ! defined($keyWord) || ! defined($dst) ){
        confess("Must call with dst, date, and key input keyword args.  See Documentation.\n");
    }
    
    # OK, now dkresolve the path using date and keyword
    $src = DKResolve->resolve( 
                               string => $self->path,
                               date   => $date,
                               key    => $keyWord
                             );
                  
    # need to construct the full local path
    $dst = File::Spec->catfile($dst, basename($src));
    
    # finally, get the file
    my $status = $self->{_ftp}->get($src,$dst);
    
    # bulk if status != 1 
    # but only say something if not already in debug mode.
    # if debug on then no reason to repeat the message.
    if (! $status && !$self->{_shouldDebug}){
        carp("Xfer error: $src --> $dst  ","Server says: ",$self->{_ftp}->message);
    }
    
    return ($status, $self->{_ftp}->message);
        
}

sub close{
    my $self = shift;
    $self -> {_ftp} -> quit();
}

sub stringify{
    my $self = shift;
    return $self->host.":".$self->path;
}


1;

