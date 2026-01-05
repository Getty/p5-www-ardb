package WWW::ARDB::CLI::Cmd::Quests;

# ABSTRACT: List quests command

use Moo;
use MooX::Cmd;
use MooX::Options;

our $VERSION = '0.002';

option search => (
    is      => 'ro',
    short   => 's',
    format  => 's',
    doc     => 'Search quests by title',
);

option trader => (
    is      => 'ro',
    short   => 't',
    format  => 's',
    doc     => 'Filter by trader name',
);

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
