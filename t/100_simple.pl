#!/usr/bin/perl

use strict;
use warnings;

open(STDERR, ">&STDOUT");

use Devel::GlobalDestruction::Warn;


package My::Class;

sub new { return bless {} => shift }


package main;

our $obj = My::Class->new;
