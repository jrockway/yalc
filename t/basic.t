use strict;
use warnings;
use Test::More;
use Devel::Peek;

use YALC;

my $YALC = YALC->new;

sub test($;$) {
    my ($count, $msg) = @_;
    is($YALC->remaining_object_count, $count, $msg);
}

sub new()  { $YALC = YALC->new }
sub add($) { $YALC->add($_[0]) }

new;

test 0, 'no objects yet';

{ # not a leak
    my $hash = { foo => 42, bar => { foo => 42 }, baz => [{}] };

    add $hash;

    test 4, 'added a structure';
}

test 0, 'went away';

{ # also not a leak
    my $hash = { foo => 42, bar => { foo => 42 }, baz => [{}] };

    add $hash;
    add $hash->{bar};

    test 4, 'added a structure';
}

test 0, 'went away';

{ # a leak

    my $hash = { foo => 42, bar => { foo => 42 }, baz => [{}] };
    $hash->{bar}{bar} = $hash->{bar};

    add $hash;

    test 4, 'added a leaky structure';
}

test 1, 'OH NOES, a leak';
new;
{
    my $hash = {};
    my $code = sub {
        $hash->{$_[0]} = $_[1];
    };

    add $code;

    $hash->{code} = $code;

    test 2, 'hash and code';
}

test 2, 'everything leaked';

new();

done_testing;
