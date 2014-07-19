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

    #
    #  Create teh database if it is missing.
    #
    if ($create)
    {
        $self->{ 'db' }->do(
             "CREATE TABLE string (id INTEGER PRIMARY KEY, key UNIQUE, val );");
        $self->{ 'db' }
          ->do("CREATE TABLE sets (id INTEGER PRIMARY KEY, key, val );");
    }

    #
    #  This is potentially risky, but improves the throughput by several
    # orders of magnitude.
    #
    if ( !$ENV{ 'SAFE' } )
    {
        $self->{ 'db' }->do("PRAGMA synchronous = OFF");
        $self->{ 'db' }->do("PRAGMA journal_mode = MEMORY");
    }

    return $self;
}



#
#  Get the value of a key.
#
sub get
{
    my ( $self, $key ) = (@_);

    if ( !$self->{ 'get' } )
    {
        $self->{ 'get' } =
          $self->{ 'db' }->prepare("SELECT val FROM string WHERE key=?");
    }
    $self->{ 'get' }->execute($key);
    my $x = $self->{ 'get' }->fetchrow_array() || "";
    $self->{ 'get' }->finish();
    return ($x);
}



#
#  Set the value of a key.
#
sub set
{
    my ( $self, $key, $val ) = (@_);

    if ( !$self->{ 'ins' } )
    {
        $self->{ 'ins' } =
          $self->{ 'db' }
          ->prepare("INSERT OR REPLACE INTO string (key,val) VALUES( ?,? )");
    }
    $self->{ 'ins' }->execute( $key, $val );
    $self->{ 'ins' }->finish();

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

    if ( !$self->{ 'del' } )
    {
        $self->{ 'del' } =
          $self->{ 'db' }->prepare("DELETE FROM string WHERE key=?");
    }
    $self->{ 'del' }->execute($key);
    $self->{ 'del' }->finish();
}


#
#  Set members
#
sub smembers
{
    my ( $self, $key ) = (@_);

    if ( !$self->{ 'smembers' } )
    {
        $self->{ 'smembers' } =
          $self->{ 'db' }->prepare("SELECT val FROM sets WHERE key=?");
    }
    $self->{ 'smembers' }->execute($key);

    my $vals;
    while ( my ($name) = $self->{ 'smembers' }->fetchrow_array )
    {
        push( @$vals, { type => '+', data => $name } );
    }
    $self->{ 'smembers' }->finish();

    return ($vals);
}

#
#  Add to set.
#
sub sadd
{
    my ( $self, $key, $val ) = (@_);

    if ( !$self->{ 'sadd' } )
    {
        $self->{ 'sadd' } =
          $self->{ 'db' }->prepare("INSERT INTO sets (key,val) VALUES( ?,? )");
    }
    $self->{ 'sadd' }->execute( $key, $val );
    $self->{ 'sadd' }->finish();
}


#
#  Remove from a set.
#
sub srem
{
    my ( $self, $key, $val ) = (@_);

    if ( !$self->{ 'srem' } )
    {
        $self->{ 'srem' } =
          $self->{ 'db' }->prepare("DELETE FROM sets WHERE (key=? AND val=?)");
    }
    $self->{ 'srem' }->execute( $key, $val );
    $self->{ 'srem' }->finish();
}



#
#  End of the module.
#
1;
