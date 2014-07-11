#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More qw! no_plan !;


use Redis;


#
#  Connect to our faux server
#
my $r = Redis->new();


#
#  AN empty value shoul return an empty-string.
#
#  Set it and confirm.
#
is( "", $r->get( "foo" ), "An empty key is undefined" );
$r->set( "foo", "bar" );
is( $r->get( "foo"), "bar", "Fetching a value works" );
$r->del( "foo" );
is( "", $r->get( "foo" ), "An deleted key is undefined" );

#
#
#  Getting an empty value is empty
#
is( $r->get( "count" ), "" , "No count is empty" );
ok( $r->incr( "count" ) );
is( $r->get( "count" ), 1 , "incr'd count is 1" );
ok( $r->incr( "count" ) );
is( $r->get( "count" ), 2, "incr'd count is 2" );

#
#  Deleting a count works
#
$r->del( "count" );
is( $r->get( "count" ), "" , "Deleted value is gone" );
