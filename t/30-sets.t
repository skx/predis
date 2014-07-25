#!/usr/bin/perl -Ilib/ -I../lib/

use strict;
use warnings;

use Test::More qw! no_plan !;
use File::Temp qw! tempfile !;
use File::Path qw! rmtree !;

BEGIN {use_ok('Predis::Backend::SQLite');}
require_ok('Predis::Backend::SQLite');



#
#  Load the SQLite backend
#
my $mod    = "SQLite";
my $module = "Predis::Backend::$mod";

## no critic (Eval)
eval( "use " . $module );
## use critic

is( $@, "", "Loading the backend succeeded: $module" );

#
#  Create a temporary file - but make sure it doesn't exist.
#
my ( undef, $filename ) = tempfile();
ok( -e $filename, "Created temporary file" );
unlink($filename);
ok( !-e $filename, "Removed temporary file" );

#
#  Instantiate the back-end
#
my $backend = $module->new( path => $filename );
isa_ok( $backend, $module, "The back-end has the correct type" );
is( $backend->name(), $module, "The back-end has the correct name" );


#
#  OK the set "kemp" should be empty.
#
is( $backend->scard("kemp"),    0,     "The empty set is empty" );
is( $backend->smembers("kemp"), undef, "The empty set is empty" );

#
#  Add some members
#
foreach my $str (qw! steve kirsi helen !)
{
    $backend->sadd( "kemp", $str );
}

is( $backend->scard("kemp"), 3, "The populated set has members" );

#
#  Get the members
#
foreach my $m ( @{ $backend->smembers("kemp") } )
{
    $m = $m->{ 'data' };
    ok( $m =~ /(steve|kirsi|helen)/, "The members are correct: $m" );
}

#
#  Delete a member
#
$backend->srem( "kemp", "helen" );
is( $backend->scard("kemp"), 2, "After deleting a member we have two entries" );

#
#  Which are still correct
#
foreach my $m ( @{ $backend->smembers("kemp") } )
{
    $m = $m->{ 'data' };
    ok( $m =~ /(steve|kirsi)/, "The members are correct: $m" );
}

#
#  NOTE: del is for string values
#
$backend->del("kemp");
$backend->del("kemp");
is( $backend->scard("kemp"), 2, "After deleting a member we have two entries" );


#
#  Remove both members
#
$backend->srem( "kemp", "steve" );
$backend->srem( "kemp", "kirsi" );
is( $backend->scard("kemp"), 0, "We have no more members" );


#
#  Cleanup
#
unlink($filename);
