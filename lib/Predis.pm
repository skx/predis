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
        print STDERR "INCR($key)\n";

        return ( { type => ':', data => $backend->incr($key) } );
    },

    #
    #  Decrement an integer.
    #
    decr => sub {
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        print STDERR "DECR($key)\n";

        return ( { type => ':', data => $backend->decr($key) } );

    },


    #
    #  Delete a key.
    #
    del => sub {
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        print STDERR "DEL($key)\n";

        $backend->del($key);

        return ( { type => ':', data => 1 } );
    },


    #
    #  Expire a key: NOP
    #
    expire => sub {
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        print STDERR "EXPIRE($key)\n";

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
        print STDERR "GET($key)\n";

        return ( { type => '+', data => $backend->get($key) } );
    },


    set => sub {

        #
        #  This is nasty
        #
        my $data = shift;
        my $key  = $data->{ 'data' }[1]->{ 'data' };
        my $val  = $data->{ 'data' }[2]->{ 'data' };
        print STDERR "SET($key, $val)\n";

        $backend->set( $key, $val );

        return ( { type => '+', data => "OK" } );
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

    $backend = $supplied{'backend'} || die "No backend";

    return $self;
}


sub serve
{

    my $c = AnyEvent->condvar;
    tcp_server undef, 6379, sub {
        my $fh = shift;
        my $redis = Protocol::Redis->new( api => 1 );

        $redis->on_message(
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
                               $redis->parse($chunk);
                           } );
    };



    $c->recv;

}


1;
