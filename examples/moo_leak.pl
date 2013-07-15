#!/usr/bin/perl

package My::Class;

use Moo;

use lib 'lib', '../lib';
use Devel::GlobalDestruction::Warn;

has 'ref' => (is => 'rw');


package main;

my $obj1 = My::Class->new();
my $obj2 = My::Class->new();

# cycled refs
$obj1->ref($obj2);
$obj2->ref($obj1);

# end without dispose
