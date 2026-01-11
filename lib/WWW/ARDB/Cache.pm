package WWW::ARDB::Cache;

# ABSTRACT: File-based cache for WWW::ARDB

use Moo;
use Types::Standard qw( Str InstanceOf );
use Path::Tiny qw( path );
use Digest::MD5 qw( md5_hex );
use JSON::MaybeXS qw( encode_json decode_json );
use namespace::clean;

our $VERSION = '0.003';

=head1 SYNOPSIS

    use WWW::ARDB::Cache;

    my $cache = WWW::ARDB::Cache->new;

    # Store data
    $cache->set('items', {}, $data);

    # Retrieve data
    my $cached = $cache->get('items', {});

    # Clear specific endpoint
    $cache->clear('items');

    # Clear all
    $cache->clear;

=head1 DESCRIPTION

This module provides file-based caching for API responses. Cache files are
stored in the XDG cache directory on Unix systems (C<~/.cache/ardb>) or
C<LOCALAPPDATA> on Windows (C<%LOCALAPPDATA%\ardb>).

=cut

has cache_dir => (
    is      => 'lazy',
    isa     => InstanceOf['Path::Tiny'],
    coerce  => sub { ref $_[0] ? $_[0] : path($_[0]) },
    builder => '_build_cache_dir',
);

=attr cache_dir

L<Path::Tiny> object for the cache directory. Defaults to platform-specific
location: C<~/.cache/ardb> on Unix or C<%LOCALAPPDATA%/ardb> on Windows.

=cut

sub _build_cache_dir {
    my $self = shift;

    my $base;
    if ($^O eq 'MSWin32') {
        $base = path($ENV{LOCALAPPDATA} || $ENV{APPDATA} || $ENV{HOME});
    } else {
        $base = path($ENV{XDG_CACHE_HOME} || "$ENV{HOME}/.cache");
    }

    my $dir = $base->child('ardb');
    $dir->mkpath unless $dir->exists;

    return $dir;
}

has namespace => (
    is      => 'ro',
    isa     => Str,
    default => 'default',
);

=attr namespace

String prefix for cache keys. Defaults to C<default>. Can be used to segregate
caches for different purposes.

=cut

sub get {
    my ($self, $endpoint, $params) = @_;

    my $file = $self->_cache_file($endpoint, $params);
    return unless $file->exists;

    my $content = $file->slurp_utf8;
    my $cached = decode_json($content);

    return $cached->{data};
}

=method get

    my $cached = $cache->get($endpoint, \%params);

Retrieve cached data for an endpoint with the given parameters. Returns the
cached data or undef if not found.

=cut

sub set {
    my ($self, $endpoint, $params, $data) = @_;

    my $file = $self->_cache_file($endpoint, $params);
    $file->parent->mkpath unless $file->parent->exists;

    my $cache_data = {
        timestamp => time(),
        endpoint  => $endpoint,
        data      => $data,
    };

    $file->spew_utf8(encode_json($cache_data));
}

=method set

    $cache->set($endpoint, \%params, $data);

Store data in cache for an endpoint with the given parameters.

=cut

sub clear {
    my ($self, $endpoint) = @_;

    if ($endpoint) {
        my $pattern = $self->_cache_key($endpoint, {});
        $pattern =~ s/_[a-f0-9]+$//;
        for my $file ($self->cache_dir->children) {
            if ($file->basename =~ /^\Q$pattern\E/) {
                $file->remove;
            }
        }
    } else {
        for my $file ($self->cache_dir->children) {
            $file->remove if $file->is_file;
        }
    }
}

=method clear

    $cache->clear($endpoint);  # Clear specific endpoint
    $cache->clear;             # Clear all cached data

Clear cached data. If C<$endpoint> is provided, only clears cache files for
that endpoint. Otherwise clears all cache files.

=cut

sub _cache_key {
    my ($self, $endpoint, $params) = @_;

    my $key = $self->namespace . '_' . $endpoint;
    $key =~ s/[\/\s]/_/g;

    if ($params && %$params) {
        my $param_str = encode_json($params);
        $key .= '_' . md5_hex($param_str);
    }

    return $key;
}

sub _cache_file {
    my ($self, $endpoint, $params) = @_;

    my $key = $self->_cache_key($endpoint, $params);
    return $self->cache_dir->child($key . '.json');
}

1;
