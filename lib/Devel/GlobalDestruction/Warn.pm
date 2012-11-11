package Devel::GlobalDestruction::Warn;

=head1 NAME

Devel::GlobalDestruction::Warn - Warn if object is at global destruction

=head1 SYNOPSIS

  package Foo;
  use Devel::GlobalDestruction::Warn;

From command line:

  $ perl -MDevel::GlobalDestruction::Warn leak.pl

=head1 DESCRIPTION

Global destruction means that you didn't freed the resources previously. It
might be a sight of memory leaking so it is very useful to warn if any
destructor was called at global destruction.

=for readme stop

=cut


use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Devel::GlobalDestruction;
use Carp ();
use Scalar::Util qw( blessed reftype refaddr );
use Symbol::Util qw(:all);

use namespace::functions;

# Mouse::XS doesn't use bless
$ENV{MOUSE_PUREPERL} = 1;

$Carp::CarpInternal{$_} = 1 foreach (__PACKAGE__, qw(
    Mouse::Meta::Method::Constructor Mouse::Meta::Class Mouse::Object
    Class::MOP::Class Class::MOP::Instance
    Moose::Meta::Class Moose::Object
) );

our %Excludes = map { $_ => 1 } qw(
    Any
    AnyEvent::Log::Ctx
    ArrayRef Bool
    Class::MOP::Attribute
    Class::MOP::Class Class::MOP::Class::Immutable::Class::MOP::Class
    Class::MOP::Instance
    Class::MOP::Method Class::MOP::Method::Accessor Class::MOP::Method::Constructor
    Class::MOP::Method::Meta Class::MOP::Method::Wrapped
    Class::MOP::Package
    ClassName CodeRef
    Config
    DateTime::Format::Builder::Parser DateTime::Format::Builder::Parser::Regex
    DateTime::Infinite::Future DateTime::Infinite::Past
    DateTime::Locale::en_US
    DateTime::TimeZone::Floating
    Defined
    Encode::utf8
    Errno
    FileHandle GlobRef HashRef Int Item Maybe
    Moose::Meta::Attribute Moose::Meta::Class Moose::Meta::Instance
    Moose::Meta::Method::Accessor Moose::Meta::Method::Meta
    Moose::Meta::TypeConstraint Moose::Meta::TypeConstraint::Class
    Moose::Meta::TypeConstraint::Parameterizable Moose::Meta::TypeConstraint::Registry
    Mouse::Meta::Attribute Mouse::Meta::Class
    Mouse::Meta::Role Mouse::Meta::Role::Composite
    Mouse::Meta::TypeConstraint
    Mouse::Object Mouse::PurePerl
    Num Object Ref RegexpRef RoleName ScalarRef Str Undef
    POSIX::SigRt
    utf8
    Value
);

our (%Seen, %Trace);

my $my_bless = sub {
    my ($ref, $class) = @_;
    $class = scalar caller unless defined $class;
    return CORE::bless($ref, $class);
};

my $wrap_destroy = sub {
    my ($class) = @_;
    my $orig_destroy = fetch_glob("${class}::DESTROY", 'CODE');
    no warnings 'redefine';
    *{ fetch_glob("${class}::DESTROY") } = sub {
        my ($obj) = @_;
        $orig_destroy->($obj) if $orig_destroy;
        my $class = blessed $obj;
        my $objstr = sprintf "%s=%s(0x%x)", $class, reftype $obj, refaddr $obj;
        warn($Trace{$objstr} || "DESTROY of $objstr") if in_global_destruction and not exists $Excludes{$class};
    };
};

my $carp = \&Carp::croak;

my $wrap_bless = sub {
    my ($class, $filter) = @_;
    $filter = '' unless defined $filter;
    no warnings 'redefine';
    *CORE::GLOBAL::bless = sub {
        my ($ref, $class) = @_;
        $class = scalar caller unless defined $class;
        my $obj = CORE::bless($ref, $class);
        if ($class =~ /$filter/ and not exists $Excludes{$class}) {
            if (not $Seen{$class}) {
                $wrap_destroy->($class) unless $Seen{$class};
                $Seen{$class} = 1;
            };
            my $objstr = sprintf "%s=%s(0x%x)", blessed $obj, reftype $obj, refaddr $obj;
            local $@;
            eval { $carp->("DESTROY of $objstr created") };
            $Trace{$objstr} = $@;
        };
        return $obj;
    };
};

sub import {
    my ($class, $filter) = @_;
    if ($ENV{PERL_DEVEL_GLOBALDESTRUCTION_WARN_VERBOSE} or $ENV{PERL_DGW_VERBOSE}) {
        $carp = \&Carp::confess;
    };
    my $caller = caller;
    $wrap_bless->($caller, $filter);
    return;
};

no namespace::functions;

1;


=for readme continue

=head1 ENVIRONMENT

If the C<PERL_DEVEL_GLOBALDESTRUCTION_WARN_VERBOSE> or C<PERL_DGW_VERBOSE>
variable is true value, the full stack trace will be outputed.

=head1 SEE ALSO

Similar tools which detects memory leaks:

L<Devel::Leak::Object>, L<Devel::LeakGuard::Object>.

Some tools which help to prevent memory leaks:

L<Resource::Dispose>, L<Object::Destroyer>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Devel-GlobalDestruction-Warn/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Devel-GlobalDestruction-Warn>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2012 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
