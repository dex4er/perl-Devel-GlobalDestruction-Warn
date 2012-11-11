#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;

use Test::More tests => 1;

my $inc = join ' ', map { "-I\"$_\"" } @INC;
my $dir = dirname(__FILE__);
my $status = `$^X $inc $dir/100_simple.pl`;

like $status, qr/DESTROY/, 'DESTROY captured';
