package YALC;
# ABSTRACT: yet another leak checker
use Moose;
use MooseX::ClassAttribute;
use MooseX::Types::Set::Object;

use Set::Object::Weak;
use YALC::Visitor;

use true;
use namespace::autoclean;

# convenience singleton
class_has 'instance' => (
    is         => 'ro',
    isa        => 'YALC',
    lazy_build => 1,
);

sub _build_instance { shift->new(@_) }

has 'object_set' => (
    isa     => 'Set::Object',
    default => sub { Set::Object::Weak->new },
    handles => {
        'shallow_add'            => 'insert',
        'remaining_objects'      => 'members',
        'remaining_object_count' => 'size',
    },
);

sub add {
    my ($self, $o) = @_;

    my $v = YALC::Visitor->new(
        yalc => $self,
    );
    $v->visit($o);
    return;
}

__PACKAGE__->meta->make_immutable;

__END__

=heady SYNOPSIS

   use YALC;
   my $yalc = YALC->new;

   {
       my $object = make_complex_object();
       $yalc->add($object);

       my $results = operate_on $object;
       print_results $results;
   }

   if(my $count = $yalc->remaining_object_count) {
       say "You leaked $count objects: ";
       use Data::Dump::Streamer;
       print Dump($yalc->remaining_objects);
   }

=head1 DESCRIPTION

Sometimes your program leaks memory.  This module is another tool to
help you determine what's leaking.  It works by recrusively visiting
data structures that you pass to it, adding each reference to a weak
set.  Later, after the objects should be out of scope, you check to
see if the objects are still in the set.  If they are, they leaked.
If they aren't, they didn't leak.  That's it.

An "object" is anything you can store in a perl variable.

=head1 METHODS

=head2 new

Create a new YALC object.

=head2 instance

Retrieve (creating if necessary) the global YALC object.  This is for
convenience, so you don't have to pass an object around wherever you
need one:


    sub foo {
        YALC->instance->add($foo);
    }

    sub main {
        foo();
        say YALC->instance->remaining_object_count;
    }

In that case, anything in C<$foo> that leaked will be reported.

=head2 add($object)

Add an object to the leak-tracking set, recrusively adding any objects
that it references.

=head2 shallow_add($object)

Only add C<$object>, not anything it references.

=head2 remaining_objects

Return all objects that are still in the set; these are the ones that
leaked if they were supposed to have been cleaned up by now.

=head2 remaining_object_count

Return how many remaining objects there are.

