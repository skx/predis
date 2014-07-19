#
#  Storage abstraction for BerkeleyDB
#
package Predis::Backend::BDB;


use strict;
use warnings;
use BerkeleyDB;

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

    my $file = $supplied{ 'path' } || $ENV{ 'HOME' } . "/.predis.bdb";


    my $db = tie %hash, 'BerkeleyDB::Hash',
      -Filename => $file,
      -Flags    => DB_CREATE or
      die "Cannot open $file: $!\n";


    return $self;
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
