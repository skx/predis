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
    #  AN empty value shoul return an empty-string.
    #
    #  Set it and confirm.
    #
    is( "", $redis->get("foo"), "An empty key is undefined" );
    $redis->set( "foo", "bar" );
    is( $redis->get("foo"), "bar", "Fetching a value works" );
    $redis->del("foo");
    is( "", $redis->get("foo"), "An deleted key is undefined" );

    #
    #
    #  Getting an empty value is empty
    #
    is( $redis->get("count"), "", "No count is empty" );
    ok( $redis->incr("count") );
    is( $redis->get("count"), 1, "incr'd count is 1" );
    ok( $redis->incr("count") );
    is( $redis->get("count"), 2, "incr'd count is 2" );

    #
    #  Deleting a count works
    #
    $redis->del("count");
    is( $redis->get("count"), "", "Deleted value is gone" );



}


