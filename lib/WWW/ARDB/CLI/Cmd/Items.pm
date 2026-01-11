package WWW::ARDB::CLI::Cmd::Items;

# ABSTRACT: List items command

use Moo;
use MooX::Cmd;
use MooX::Options;

our $VERSION = '0.002';

=head1 SYNOPSIS

    ardb items
    ardb items --search guitar
    ardb items --type weapon
    ardb items --rarity legendary

=head1 DESCRIPTION

CLI command to list all items from the ARC Raiders Database with optional
filtering by name, type, or rarity.

=cut

option search => (
    is      => 'ro',
    short   => 's',
    format  => 's',
    doc     => 'Search items by name',
);

=opt search

    ardb items --search guitar
    ardb items -s medkit

Case-insensitive substring search for items by name.

=cut

option type => (
    is      => 'ro',
    short   => 't',
    format  => 's',
    doc     => 'Filter by type',
);

=opt type

    ardb items --type weapon
    ardb items -t "quick use"

Filter items by type (exact match, case-insensitive).

=cut

option rarity => (
    is      => 'ro',
    short   => 'r',
    format  => 's',
    doc     => 'Filter by rarity',
);

=opt rarity

    ardb items --rarity legendary
    ardb items -r epic

Filter items by rarity level (exact match, case-insensitive).

=cut

sub execute {
    my ($self, $args, $chain) = @_;

    my $app = $chain->[0];
    my $items = $app->api->items;

    # Apply filters
    if ($self->search) {
        my $search = lc($self->search);
        $items = [ grep { index(lc($_->name), $search) >= 0 } @$items ];
    }

    if ($self->type) {
        my $type = lc($self->type);
        $items = [ grep { $_->type && lc($_->type) eq $type } @$items ];
    }

    if ($self->rarity) {
        my $rarity = lc($self->rarity);
        $items = [ grep { $_->rarity && lc($_->rarity) eq $rarity } @$items ];
    }

    if ($app->json) {
        $app->output_json([ map { $_->_raw } @$items ]);
        return;
    }

    if (@$items == 0) {
        print "No items found.\n";
        return;
    }

    printf "%-30s %-12s %-15s %8s\n", 'Name', 'Rarity', 'Type', 'Value';
    print "-" x 70 . "\n";

    for my $item (@$items) {
        printf "%-30s %-12s %-15s %8s\n",
            substr($item->name, 0, 30),
            $item->rarity // '-',
            substr($item->type // '-', 0, 15),
            $item->value // '-';
    }

    print "\n" . scalar(@$items) . " items found.\n";
}

1;
