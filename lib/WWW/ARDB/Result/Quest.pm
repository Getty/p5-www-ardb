package WWW::ARDB::Result::Quest;

# ABSTRACT: Quest result object for WWW::ARDB

use Moo;
use Types::Standard qw( Str Int Num ArrayRef HashRef Maybe );
use namespace::clean;

our $VERSION = '0.003';

=head1 SYNOPSIS

    my $quest = $api->quest('picking_up_the_pieces');

    print $quest->title;           # "Picking Up The Pieces"
    print $quest->trader_name;     # "Shani"
    print $quest->trader_type;     # "Security"

    for my $step (@{$quest->steps}) {
        printf "- %s (x%d)\n", $step->{title}, $step->{amount};
    }

=head1 DESCRIPTION

Result object representing a quest from the ARC Raiders Database. Created via
L<WWW::ARDB> methods like C<quests()> and C<quest()>.

=cut

has id => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=attr id

String. Unique identifier for the quest (e.g., C<picking_up_the_pieces>).

=cut

has title => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=attr title

String. Quest title.

=cut

has description => (
    is      => 'ro',
    isa     => Maybe[Str],
    default => sub { undef },
);

=attr description

String or undef. Quest description or narrative text.

=cut

has maps => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=attr maps

ArrayRef of HashRefs. Available maps/locations for this quest.

=cut

has steps => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=attr steps

ArrayRef of HashRefs. Quest objectives, each with C<title> and C<amount>.

=cut

has trader => (
    is      => 'ro',
    isa     => Maybe[HashRef],
    default => sub { undef },
);

=attr trader

HashRef or undef. Quest giver information including C<id>, C<name>, C<type>,
C<description>, C<image>, C<icon>.

=cut

has required_items => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=attr required_items

ArrayRef of HashRefs. Items needed to complete the quest.

=cut

has rewards => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
);

=attr rewards

ArrayRef of HashRefs. Quest completion rewards.
Only populated for detail endpoint (C<quest($id)>).

=cut

has xp_reward => (
    is      => 'ro',
    isa     => Maybe[Num],
    default => sub { undef },
);

=attr xp_reward

Number or undef. Experience points awarded for completing the quest.

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
        id             => $data->{id},
        title          => $data->{title},
        description    => $data->{description},
        maps           => $data->{maps} // [],
        steps          => $data->{steps} // [],
        trader         => $data->{trader},
        required_items => $data->{requiredItems} // [],
        rewards        => $data->{rewards} // [],
        xp_reward      => $data->{xpReward},
        updated_at     => $data->{updatedAt},
        _raw           => $data,
    );
}

=method from_hashref

    my $quest = WWW::ARDB::Result::Quest->from_hashref($data);

Class method. Constructs a Quest object from API response data (HashRef).

=cut

sub trader_name {
    my $self = shift;
    return unless $self->trader;
    return $self->trader->{name};
}

=method trader_name

    my $name = $quest->trader_name;

Returns the quest giver's name, or undef if no trader is set.

=cut

sub trader_type {
    my $self = shift;
    return unless $self->trader;
    return $self->trader->{type};
}

=method trader_type

    my $type = $quest->trader_type;

Returns the quest giver's type/profession (e.g., C<Security>), or undef if no
trader is set.

=cut

sub map_names {
    my $self = shift;
    return [ map { $_->{name} } @{$self->maps} ];
}

=method map_names

    my $names = $quest->map_names;

Returns an ArrayRef of map names where the quest is available.

=cut

1;
