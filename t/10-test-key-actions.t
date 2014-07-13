#!/usr/bin/perl -Ilib/ -I../lib/
#
# This test assumes that redis/predis is installed and running on the localhost.
#
# Steve
# --



use strict;
use warnings;

use Test::More qw! no_plan !;
use File::Temp qw! tempdir !;


#
#  Should we skip the tests?
#
my $skip = 0;


#
#  Ensure that we have Redis installed.
#
## no critic (Eval)
eval "use Redis";
## use critic
$skip = 1 if ($@);


#
# Connect to redis
#
my $redis;
eval {$redis = new Redis();};
$skip = 1 if ($@);
$skip = 1 unless ($redis);
$skip = 1 unless ( $redis && $redis->ping() );


SKIP:
{
    skip "Redis must be running on localhost" unless ( !$skip );

    #
    #  Generate a random key for testing purposes.
    #
    my @chars = ( "A" .. "Z", "a" .. "z" );
    my $key;
    $key .= $chars[rand @chars] for 1 .. 8;


    #
    #  AN empty value shoul return an empty-string.
    #
    #  Set it and confirm.
    #
    is( "", $redis->get($key), "An empty key is undefined" );
    $redis->set( $key, "bar" );
    is( $redis->get($key), "bar", "Fetching a value works" );
    $redis->del($key);
    is( "", $redis->get($key), "An deleted key is undefined" );

    #
    #
    #  Getting an empty value is empty
    #
    is( $redis->get($key), "", "No count is empty" );
    ok( $redis->incr($key) );
    is( $redis->get($key), 1, "incr'd count is 1" );
    ok( $redis->incr($key) );
    is( $redis->get($key), 2, "incr'd count is 2" );

    #
    #  Deleting a count works
    #
    $redis->del($key);
    is( $redis->get($key), "", "Deleted value is gone" );

    #
    #  Test the incrby primitive
    #
    is( $redis->get($key), "", "No count is empty" );
    ok( $redis->incrby( $key, 20 ) );
    is( $redis->get($key), 20, "incr'd count is 20" );
    ok( $redis->incrby( $key, 20 ) );
    is( $redis->get($key), 40, "incr'd count is 40" );
    ok( $redis->decrby( $key, 10 ) );
    is( $redis->get($key), 30, "decr'd count is 30" );
    ok( $redis->decrby( $key, 10 ) );
    is( $redis->get($key), 20, "decr'd count is 30" );
    $redis->del($key);
}


