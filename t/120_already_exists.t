#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;

use Test::More tests => 2;

my $inc = join ' ', map { "-I\"$_\"" } @INC;
my $dir = dirname(__FILE__);
my $status = `$^X $inc $dir/120_already_exists.pl`;

like $status, qr/foo/, 'foo captured';
like $status, qr/DESTROY/, 'DESTROY captured';
