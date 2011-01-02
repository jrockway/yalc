package YALC::Visitor;
# ABSTRACT: Data::Visitor subclass for visiting data structures
use Moose;
use true;
use namespace::autoclean;

use PadWalker qw(closed_over); # oh yes!

extends 'Data::Visitor';

has 'yalc' => (
    is       => 'ro',
    isa      => 'YALC',
    required => 1,
    handles  => ['shallow_add'],
);

sub visit_object {
    shift->visit_ref(@_);
}

before visit_ref => sub {
    my $self = shift;

    # scalar refs cause breakage
    return if ref($_[0]) =~ /^(?:SCALAR|VSTRING|LVALUE|REF)$/;

    $self->shallow_add($_[0]);
};

sub visit_code {
    my ($self) = @_;
    $self->shallow_add($_[1]);

    my $closure = closed_over($_[1]);
    $self->visit($closure);

    return;
}

__PACKAGE__->meta->make_immutable;
