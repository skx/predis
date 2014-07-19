#!/usr/bin/perl -Ilib/
#
#  Trivial Redis-server in Perl, which proxies to SQLite.
#
# Steve
# --
#

use strict;
use warnings;

package Predis;

use AnyEvent::Strict;
use AnyEvent;
use AnyEvent::Socket;
use Protocol::Redis;


our $backend;


my %commands = (
    info => sub {
        return ( { type => '$', data => "predis_server:0.0.1\x0d\x0a" } );
    },
    ping => sub {return ( { type => '+', data => 'PONG' } );},

    #
    #  Increment an integer.
    #
    incr => sub {
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "INCR($key)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "incr" ) );

        return ( { type => ':', data => $backend->incr($key) } );
    },
    incrby => sub {
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        my $amt  = $data->{ 'data' }[2]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "INCRBY($key,$amt)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "incrby" ) );

        return ( { type => ':', data => $backend->incr( $key, $amt ) } );
    },

    #
    #  Decrement an integer.
    #
    decr => sub {
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "DECR($key)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "decr" ) );

        return ( { type => ':', data => $backend->decr($key) } );

    },
    decrby => sub {
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        my $amt  = $data->{ 'data' }[2]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "DECRBY($key,$amt)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "decrby" ) );

        return ( { type => ':', data => $backend->decr( $key, $amt ) } );

    },


    #
    #  Delete a key.
    #
    del => sub {
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "DEL($key)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "del" ) );

        $backend->del($key);

        return ( { type => ':', data => 1 } );
    },


    #
    #  Expire a key: NOP
    #
    expire => sub {
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "EXPIRE($key)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "expire" ) );

        $backend->expire($key);

        return ( { type => ':', data => 1 } );
    },


    #
    #  Get the value of a key
    #
    get => sub {

        #
        #  This is nasty
        #
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "GET($key)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "get" ) );

        return ( { type => '+', data => $backend->get($key) } );
    },

    strlen => sub {

        #
        #  This is nasty
        #
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "GET($key)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "get" ) );

        return ( { type => '+', data => length( $backend->get($key) ) } );
    },



    set => sub {

        #
        #  This is nasty
        #
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        my $val  = $data->{ 'data' }[2]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "SET($key, $val)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "set" ) );

        $backend->set( $key, $val );

        return ( { type => '+', data => "OK" } );
    },


    #
    #  Get the set members of a key
    #
    smembers => sub {

        #
        #  This is nasty
        #
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "SMEMBERS($key)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "smembers" ) );

        my @members = $backend->smembers($key);
        return ( { type => '*', data => @members } );
    },

    #
    #  Add a string to a set.
    #
    sadd => sub {

        #
        #  This is nasty
        #
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        my $val  = $data->{ 'data' }[2]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "SADD($key,$val)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "sadd" ) );

        return ( { type => '+', data => $backend->sadd( $key, $val ) } );
    },


    #
    #  Get a random member from a set.
    #
    srandommember => sub {

        #
        #  This is nasty
        #
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "SRANDOMMEMBER($key)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "srandommember" ) );

        return ( { type => '+', data => $backend->srandommember($key) } );
    },

    #
    #  Count the members in a set.
    #
    scard => sub {

        #
        #  This is nasty
        #
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "SCARD($key)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "scard" ) );

        return ( { type => '+', data => $backend->scard($key) } );
    },


    #
    #  Remove a string from a set
    #
    srem => sub {

        #
        #  This is nasty
        #
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        my $val  = $data->{ 'data' }[2]->{ 'data' };
        $ENV{ 'DEBUG' } && print STDERR "SREM($key,$val)\n";

        # Test the backend can implement the method we need.
        return ( { type => '-',
                   data => 'ERR Missing implementation for backend ' .
                     $backend->name() }
               ) unless ( UNIVERSAL::can( $backend, "srem" ) );

        return ( { type => '+', data => $backend->srem( $key, $val ) } );
    },


);

sub default
{
    my $command = shift->{ data }[0]{ data };
    {  type => '-',
       data => "ERR unknown command '$command'"
    };
}




sub new
{
    my ( $proto, %supplied ) = (@_);
    my $class = ref($proto) || $proto;

    my $self = {};
    bless( $self, $class );

    $backend = $supplied{ 'backend' } || die "No backend";
    $self->{ 'port' } = $supplied{ 'port' } || 6379;
    $self->{ 'redis' } = Protocol::Redis->new( api => 1 );
    return $self;
}


sub serve
{
    my ($self) = (@_);
    my $c = AnyEvent->condvar;
    tcp_server undef, $self->{ 'port' }, sub {
        my $fh = shift;

        $self->{ 'redis' }->on_message(
            sub {
                my ( $parser, $data ) = @_;
                my $command = $commands{ lc $data->{ data }[0]{ data } } ||
                  \&default;

                syswrite( $fh, $parser->encode( $command->($data) ) );
            } );

        my $io;
        $io = AnyEvent->io(
            fh   => $fh,
            poll => 'r',
            cb   => sub {
                undef $io unless sysread( $fh, my $chunk, 1024, 0 );
                $self->{ 'redis' }->parse($chunk);
            } );
    };



    $c->recv;

}


1;
