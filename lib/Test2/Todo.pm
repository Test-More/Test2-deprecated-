package Test2::Todo;
use strict;
use warnings;

use Carp qw/croak/;
use Test2::Util::HashBase qw/hub _filter reason/;

use Test2::API qw/test2_stack/;

sub init {
    my $self = shift;

    my $reason = $self->{+REASON};
    croak "The 'reason' attribute is required" unless defined $reason;

    my $hub = $self->{+HUB} ||= test2_stack->top;

    $self->{+_FILTER} = $hub->filter(
        sub {
            my ($active_hub, $e) = @_;
            $e->set_diag_todo(1);
            $e->set_todo($reason) if $hub == $active_hub;
            return $e;
        },
        inherit => 1
    );
}

sub end {
    my $self = shift;
    my $hub = $self->{+HUB} or return;
    $hub->unfilter($self->{+_FILTER});
    delete $self->{+HUB};
    delete $self->{+_FILTER};
}

sub DESTROY {
    my $self = shift;
    $self->end;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Todo - TODO management for Test2.

=head1 EXPERIMENTAL RELEASE

This is an experimental release. Using this right now is not recommended.

=head1 DESCRIPTION

This is a tool that lets you create and manage TODO states for tests.

=head1 SYNOPSYS

    use Test2::Todo;

    # Start the todo
    my $todo = Test2::Todo->new(reason => 'Fix later');

    # Will be considered todo, so suite still passes
    ok(0, "oops");

    # End the todo
    $todo->end;

    # TODO has ended, this test will actually fail.
    ok(0, "oops");

=head1 CONSTRUCTION OPTIONS

=over 4

=item reason (required)

The reason for the todo, this can be any defined value.

=item hub (optional)

The hub to which the TODO state should be applied. If none is provided then the
current global hub is used.

=back

=head1 METHODS

=over 4

=item $todo->end

End the todo state.

=back

=head1 OTHER NOTES

=head2 How it works

When an instance is created a filter sub is added to the L<Test2::Hub>. This
filter will set the C<todo> and C<diag_todo> attributes on all events as they
come in. When the instance is destroyed, or C<end()> is called, the filter is
removed.

When a new hub is pushed (such as when a subtest is started) the new hub will
inherit the filter, but it will only set C<diag_todo>, it will not set C<todo>
on events in child hubs.

=head2 $todo->end is called at destruction

If your C<$todo> object falls out of scope and gets garbage collected, the todo
will end.

=head2 Can I use multiple instances?

Yes. Most recently created one that is still active will win.

=head1 SOURCE

The source code repository for Test2 can be found at
F<http://github.com/Test-More/Test2/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2015 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
