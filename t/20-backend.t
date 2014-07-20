#!/usr/bin/perl -Ilib/ -I../lib/
#
# This test instantiates the back-ends and tests them.
#
# Steve
# --



use strict;
use warnings;

use Test::More qw! no_plan !;
use File::Temp qw! tempfile !;
use File::Path qw! rmtree !;

BEGIN {use_ok('Predis::Backend::SQLite');}
require_ok('Predis::Backend::SQLite');

BEGIN {use_ok('Predis::Backend::LMDB');}
require_ok('Predis::Backend::LMDB');

BEGIN {use_ok('Predis::Backend::BDB');}
require_ok('Predis::Backend::BDB');


#
#  For each backend
#
foreach my $mod (qw! BDB LMDB SQLite !)
{
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
    #  Get and set a value
    #
    $backend->set( "empty", "meow" );
    is( $backend->get("empty"), "meow", "Fetching key-value works" );

    #
    #  Now cleanup
    #
    #  Some of the backends use a filename, others use a directory.
    #
    #
    if ( -d $filename )
    {
        rmtree($filename);
    }
    else
    {
        unlink($filename);
    }
}
