package WWW::ARDB::CLI::Cmd::Quests;

# ABSTRACT: List quests command

use Moo;
use MooX::Cmd;
use MooX::Options;

our $VERSION = '0.003';

=head1 SYNOPSIS

    ardb quests
    ardb quests --search pieces
    ardb quests --trader shani

=head1 DESCRIPTION

CLI command to list all quests from the ARC Raiders Database with optional
filtering by title or trader name.

=cut

option search => (
    is      => 'ro',
    short   => 's',
    format  => 's',
    doc     => 'Search quests by title',
);

=opt search

    ardb quests --search pieces
    ardb quests -s delivery

Case-insensitive substring search for quests by title.

=cut

option trader => (
    is      => 'ro',
    short   => 't',
    format  => 's',
    doc     => 'Filter by trader name',
);

=opt trader

    ardb quests --trader shani
    ardb quests -t quinn

Case-insensitive substring search for quests by trader/quest giver name.

=cut

sub execute {
    my ($self, $args, $chain) = @_;

    my $app = $chain->[0];
    my $quests = $app->api->quests;

    # Apply filters
    if ($self->search) {
        my $search = lc($self->search);
        $quests = [ grep { index(lc($_->title), $search) >= 0 } @$quests ];
    }

    if ($self->trader) {
        my $trader = lc($self->trader);
        $quests = [ grep {
            $_->trader_name && index(lc($_->trader_name), $trader) >= 0
        } @$quests ];
    }

    if ($app->json) {
        $app->output_json([ map { $_->_raw } @$quests ]);
        return;
    }

    if (@$quests == 0) {
        print "No quests found.\n";
        return;
    }

    printf "%-35s %-15s %8s\n", 'Title', 'Trader', 'XP';
    print "-" x 60 . "\n";

    for my $quest (@$quests) {
        printf "%-35s %-15s %8s\n",
            substr($quest->title, 0, 35),
            substr($quest->trader_name // '-', 0, 15),
            $quest->xp_reward // '-';
    }

    print "\n" . scalar(@$quests) . " quests found.\n";
}

1;
