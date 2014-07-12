#!/usr/bin/perl -w -Ilib/ -I../lib/
#
#
# Steve
# --
#

use strict;
use warnings;


use Test::More qw( no_plan );


BEGIN {use_ok('Predis');}
require_ok('Predis');

BEGIN {use_ok('Predis::Backend::SQLite');}
require_ok('Predis::Backend::SQLite');

BEGIN {use_ok('Protocol::Redis');}
require_ok('Protocol::Redis');
