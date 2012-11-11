#!/usr/bin/perl

package My::Class;

use Mouse;

use lib 'lib', '../lib';
use Devel::GlobalDestruction::Warn;

has 'ref' => (is => 'rw', clearer => 'DISPOSE');

package main;

use Resource::Dispose;

resource my $obj1 = My::Class->new();
resource my $obj2 = My::Class->new();

# cycled refs
$obj1->ref($obj2);
$obj2->ref($obj1);

# clean exit after automatic dispose
