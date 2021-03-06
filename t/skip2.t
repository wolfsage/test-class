#! /usr/bin/perl -T

use strict;
use warnings;

# Override exit before Test::Class is loaded so the real override
# will be seen later.
BEGIN {
    *CORE::GLOBAL::exit = sub (;$) {
        return @_ ? CORE::exit($_[0]) : CORE::exit();
    };
}

package Local::Test;
use base qw(Test::Class);

use Test::Builder::Tester tests => 4;
use Test::More;

sub _only : Test(setup => 1) {
	my $self = shift;
	$self->builder->ok(1==1);
	$self->SKIP_ALL("skippy");
};

sub test : Test(3) {
    die "this should never run!";
};

test_out("ok 1 - test");
test_out("ok 2 # skip skippy");
test_out("ok 3 # skip skippy");
test_out("ok 4 # skip skippy");

{
    # Capture the exit from SKIP_ALL, do the tests on the TAP output,
    # and then exit for real to stop Test::Class from continuing.
    no warnings 'redefine';
    local *CORE::GLOBAL::exit = sub {
        test_test("SKIP_ALL");
        my $exit_status = @_ ? shift : 0;
        is $exit_status, 0, "exit ok";

        # Due to a quirk in Test::Builder::Tester, we're stuck with the
        # plan generated by Test::Class (4 tests)
        pass("make the plan happy");
        pass("make the plan happy");

        CORE::exit($exit_status);
    };

    Local::Test->runtests;
}
