package WWW::ARDB::CLI::Cmd::Enemies;

# ABSTRACT: List ARC enemies command

use Moo;
use MooX::Cmd;
use MooX::Options;

our $VERSION = '0.002';

=head1 SYNOPSIS

    ardb enemies
    ardb enemies --search wasp

=head1 DESCRIPTION

CLI command to list all ARC enemies from the ARC Raiders Database with optional
filtering by name.

=cut

option search => (
    is      => 'ro',
    short   => 's',
    format  => 's',
    doc     => 'Search enemies by name',
);

=opt search

    ardb enemies --search wasp
    ardb enemies -s drone

Case-insensitive substring search for enemies by name.

=cut

sub execute {
    my ($self, $args, $chain) = @_;

    my $app = $chain->[0];
    my $enemies = $app->api->arc_enemies;

    # Apply filters
    if ($self->search) {
        my $search = lc($self->search);
        $enemies = [ grep { index(lc($_->name), $search) >= 0 } @$enemies ];
    }

    if ($app->json) {
        $app->output_json([ map { $_->_raw } @$enemies ]);
        return;
    }

    if (@$enemies == 0) {
        print "No enemies found.\n";
        return;
    }

    printf "%-25s %-30s\n", 'Name', 'ID';
    print "-" x 55 . "\n";

    for my $enemy (@$enemies) {
        printf "%-25s %-30s\n",
            $enemy->name,
            $enemy->id;
    }

    print "\n" . scalar(@$enemies) . " enemies found.\n";
}

1;
