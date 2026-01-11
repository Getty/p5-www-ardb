package WWW::ARDB::Request;

# ABSTRACT: HTTP request factory for WWW::ARDB

use Moo;
use HTTP::Request;
use URI;
use namespace::clean;

our $VERSION = '0.003';

use constant BASE_URL => 'https://ardb.app/api';

=head1 SYNOPSIS

    use WWW::ARDB::Request;

    my $request = WWW::ARDB::Request->new;

    # Get HTTP::Request objects for each endpoint
    my $http_request = $request->items;
    my $http_request = $request->item('acoustic_guitar');
    my $http_request = $request->quests;
    my $http_request = $request->quest('picking_up_the_pieces');
    my $http_request = $request->arc_enemies;
    my $http_request = $request->arc_enemy('wasp');

=head1 DESCRIPTION

This module creates L<HTTP::Request> objects for the ardb.app API endpoints.
It can be used standalone for async HTTP clients like L<WWW::Chain>.

The base URL is C<https://ardb.app/api>.

=cut

sub items {
    my ($self, %params) = @_;
    return $self->_build_request('items', %params);
}

=method items

    my $request = $factory->items;

Returns an L<HTTP::Request> for C<GET /items>.

=cut

sub item {
    my ($self, $id, %params) = @_;
    return $self->_build_request("items/$id", %params);
}

=method item

    my $request = $factory->item('acoustic_guitar');

Returns an L<HTTP::Request> for C<GET /items/{id}>.

=cut

sub quests {
    my ($self, %params) = @_;
    return $self->_build_request('quests', %params);
}

=method quests

    my $request = $factory->quests;

Returns an L<HTTP::Request> for C<GET /quests>.

=cut

sub quest {
    my ($self, $id, %params) = @_;
    return $self->_build_request("quests/$id", %params);
}

=method quest

    my $request = $factory->quest('picking_up_the_pieces');

Returns an L<HTTP::Request> for C<GET /quests/{id}>.

=cut

sub arc_enemies {
    my ($self, %params) = @_;
    return $self->_build_request('arc-enemies', %params);
}

=method arc_enemies

    my $request = $factory->arc_enemies;

Returns an L<HTTP::Request> for C<GET /arc-enemies>.

=cut

sub arc_enemy {
    my ($self, $id, %params) = @_;
    return $self->_build_request("arc-enemies/$id", %params);
}

=method arc_enemy

    my $request = $factory->arc_enemy('wasp');

Returns an L<HTTP::Request> for C<GET /arc-enemies/{id}>.

=cut

sub _build_request {
    my ($self, $endpoint, %params) = @_;

    my $uri = URI->new(BASE_URL . '/' . $endpoint);
    $uri->query_form(%params) if %params;

    return HTTP::Request->new(
        GET => $uri->as_string,
        [
            'Accept' => 'application/json',
        ],
    );
}

1;
