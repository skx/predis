#
#  Storage abstraction for LMDB
#
package Predis::Backend::LMDB;


use strict;
use warnings;
use File::Path;
use LMDB_File;

our %hash;

#
# Constructor
#
sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};
    bless( $self, $class );

    my $file = $supplied{ 'path' } || $ENV{ 'HOME' } . "/.predis.lmdb";

    File::Path::mkpath( $file, 0, 0755 ) unless ( -d $file );


    my $db = tie %hash, 'LMDB_File', $file or
      die "Cannot open $file: $!\n";


    return $self;
}


#
#  Get the name of this module.
#
sub name
{
    my( $self ) = ( @_ );
    my $class = ref($self);
    return( $class );
}


#
#  NOP
#
sub expire
{

    # NOP
}

#
#  Get the value of a key.
#
sub get
{
    my ( $self, $key ) = (@_);
    return ( $hash{ $key } );
}



#
#  Set the value of a key.
#
sub set
{
    my ( $self, $key, $val ) = (@_);

    $hash{ $key } = $val;
}



#
#  Increment and return the value of an (integer) key.
#
sub incr
{
    my ( $self, $key, $amt ) = (@_);

    $amt = 1 if ( !defined($amt) );

    my $cur = $self->get($key) || 0;
    $cur += $amt;
    $self->set( $key, $cur );

    return ($cur);
}




#
#  Decrement and return the value of an (integer) key.
#
sub decr
{
    my ( $self, $key, $amt ) = (@_);

    $amt = 1 if ( !defined($amt) );

    my $cur = $self->get($key) || 0;
    $cur -= $amt;
    $self->set( $key, $cur );

    return ($cur);
}



#
#  Delete the value of a key.
#
sub del
{
    my ( $self, $key ) = (@_);

    delete $hash{ $key };
}



#
#  End of the module.
#
1;
