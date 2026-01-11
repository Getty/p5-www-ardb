package WWW::ARDB::Result::Item;

# ABSTRACT: Item result object for WWW::ARDB

use Moo;
use Types::Standard qw( Str Int Num ArrayRef HashRef Maybe );
use namespace::clean;

our $VERSION = '0.003';

=head1 SYNOPSIS

    my $item = $api->item('acoustic_guitar');

    print $item->name;          # "Acoustic Guitar"
    print $item->rarity;        # "legendary"
    print $item->type;          # "quick use"
    print $item->value;         # 7000
    print $item->icon_url;      # Full URL to icon

=head1 DESCRIPTION

Result object representing an item from the ARC Raiders Database. Created via
L<WWW::ARDB> methods like C<items()> and C<item()>.

=cut

has id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=attr id

String. Unique identifier for the item (e.g., C<acoustic_guitar>).

=cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=attr name

String. Display name of the item.

=cut

has description => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

=attr description

String or undef. Item description text.

=cut

has rarity => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

=attr rarity

String or undef. Rarity level: C<legendary>, C<epic>, C<rare>, C<uncommon>, C<common>.

=cut

has type => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

=attr type

String or undef. Item category (e.g., C<quick use>, C<weapon>, C<armor>).

=cut

has value => (
    is      => 'ro',
    isa     => Maybe[Num],
    default => sub { undef },
);

=attr value

Number or undef. Item value in credits.

=cut

has weight => (
    is      => 'ro',
    isa     => Maybe[Num],
    default => sub { undef },
);

=attr weight

Number or undef. Item weight.

=cut

has stack_size => (
    is      => 'ro',
    isa     => Maybe[Int],
    default => sub { undef },
);

=attr stack_size

Integer or undef. Maximum stack size for the item.

=cut

has icon => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

=attr icon

String or undef. Path to icon image (use C<icon_url()> for full URL).

=cut

has found_in => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=attr found_in

ArrayRef of Strings. Locations where this item can be found.

=cut

has maps => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=attr maps

ArrayRef. Maps where this item appears.

=cut

has breakdown => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=attr breakdown

ArrayRef of HashRefs. Components obtained when breaking down this item.
Only populated for detail endpoint (C<item($id)>).

=cut

has crafting => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=attr crafting

ArrayRef of HashRefs. Materials required to craft this item.
Only populated for detail endpoint (C<item($id)>).

=cut

has updated_at => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

=attr updated_at

String or undef. ISO 8601 timestamp of last update.

=cut

has _raw => (
    is      => 'ro',
    isa     => HashRef,
    default => sub { {} },
);

sub from_hashref {
    my ($class, $data) = @_;

    return $class->new(
        id          => $data->{id},
        name        => $data->{name},
        description => $data->{description},
        rarity      => $data->{rarity},
        type        => $data->{type},
        value       => $data->{value},
        weight      => $data->{weight},
        stack_size  => $data->{stackSize},
        icon        => $data->{icon},
        found_in    => $data->{foundIn} // [],
        maps        => $data->{maps} // [],
        breakdown   => $data->{breakdown} // [],
        crafting    => $data->{crafting} // [],
        updated_at  => $data->{updatedAt},
        _raw        => $data,
    );
}

=method from_hashref

    my $item = WWW::ARDB::Result::Item->from_hashref($data);

Class method. Constructs an Item object from API response data (HashRef).

=cut

sub icon_url {
    my $self = shift;
    return unless $self->icon;
    return 'https://ardb.app' . $self->icon if $self->icon =~ m{^/};
    return $self->icon;
}

=method icon_url

    my $url = $item->icon_url;

Returns the full URL to the item's icon image, or undef if no icon is set.
Automatically prepends C<https://ardb.app> to relative paths.

=cut

1;
