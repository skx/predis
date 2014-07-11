#
#  Storage abstraction for SQLite
#
package Predis::Backend::SQLite;


use strict;
use warnings;
use DBI;


#
# Constructor
#
sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};
    bless( $self, $class );

    my $file = $supplied{ 'path' } || $ENV{ 'HOME' } . "/.predis.db";

    my $create = 1;
    $create = 0 if ( -e $file );

    $self->{ 'db' } =
      DBI->connect( "dbi:SQLite:dbname=$file", "", "", { AutoCommit => 1 } );

    if ($create)
    {
        $self->{ 'db' }
          ->do("CREATE TABLE store (id INTEGER PRIMARY KEY, key, val );");
    }

    return $self;
}



#
#  Get the value of a key.
#
sub get
{
    my ( $self, $key ) = (@_);

    my $sql = $self->{ 'db' }->prepare("SELECT val FROM store WHERE key=?");
    $sql->execute($key);
    my $x = $sql->fetchrow_array() || "";
    $sql->finish();
    return ($x);
}



#
#  Set the value of a key.
#
sub set
{
    my ( $self, $key, $val ) = (@_);

    my $sql = $self->{ 'db' }->prepare("DELETE FROM store WHERE key=?");
    $sql->execute($key);
    $sql->finish();

    $sql =
      $self->{ 'db' }->prepare("INSERT INTO store (key,val) VALUES( ?,? )");
    $sql->execute( $key, $val );
    $sql->finish();
}



#
#  Increment and return the value of an (integer) key.
#
sub incr
{
    my ( $self, $key ) = (@_);

    my $cur = $self->get($key) || 0;
    $cur += 1;
    $self->set( $key, $cur );

    return ($cur);
}




#
#  Decrement and return the value of an (integer) key.
#
sub decr
{
    my ( $self, $key ) = (@_);

    my $cur = $self->get($key) || 0;
    $cur -= 1;
    $self->set( $key, $cur );

    return ($cur);
}



#
#  Delete the value of a key.
#
sub del
{
    my ( $self, $key ) = (@_);

    my $sql = $self->{ 'db' }->prepare("DELETE FROM store WHERE key=?");
    $sql->execute($key);
    $sql->finish();
}



#
#  End of the module.
#
1;
