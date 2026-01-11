package WWW::ARDB::CLI::Cmd::Enemy;

# ABSTRACT: Show ARC enemy details command

use Moo;
use MooX::Cmd;
use JSON::MaybeXS;

our $VERSION = '0.003';

=head1 SYNOPSIS

    ardb enemy wasp
    ardb enemy drone --json

=head1 DESCRIPTION

CLI command to show detailed information for a specific ARC enemy from the ARC
Raiders Database, including drop table and locations.

=cut

sub execute {
    my ($self, $args, $chain) = @_;
    my $app = $chain->[0];

    my $id = $args->[0];
    unless ($id) {
        print "Usage: ardb enemy <id>\n";
        print "Example: ardb enemy wasp\n";
        return;
    }

    my $enemy = $app->api->arc_enemy($id);

    unless ($enemy) {
        print "Enemy not found: $id\n";
        return;
    }

    if ($app->json) {
        print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode($enemy->_raw);
        return;
    }

    print "=" x 60 . "\n";
    print $enemy->name . "\n";
    print "=" x 60 . "\n\n";

    print "ID:    " . $enemy->id . "\n";

    if ($enemy->icon) {
        print "Icon:  " . $enemy->icon_url . "\n";
    }

    if ($enemy->image) {
        print "Image: " . $enemy->image_url . "\n";
    }

    if (@{$enemy->drop_table}) {
        print "\nDrop Table:\n";
        printf "  %-25s %-12s %8s\n", 'Item', 'Rarity', 'Value';
        print "  " . "-" x 48 . "\n";

        for my $drop (@{$enemy->drop_table}) {
            printf "  %-25s %-12s %8s\n",
                substr($drop->{name}, 0, 25),
                $drop->{rarity} // '-',
                $drop->{value} // '-';
        }
    }

    if (@{$enemy->related_maps}) {
        print "\nLocations:\n";
        for my $map (@{$enemy->related_maps}) {
            print "  - " . $map->{name} . "\n";
        }
    }

    print "\nLast Updated: " . ($enemy->updated_at // 'unknown') . "\n";
}

1;
