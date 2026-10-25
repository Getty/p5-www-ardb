#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use JSON::MaybeXS qw( encode_json decode_json );

use WWW::ARDB::Cache;

my $tmpdir = tempdir(CLEANUP => 1);

my $cache = WWW::ARDB::Cache->new(cache_dir => $tmpdir);
isa_ok($cache, 'WWW::ARDB::Cache');

# Test get on empty cache
my $result = $cache->get('items', {});
is($result, undef, 'Empty cache returns undef');

# Test set and get
my $data = { foo => 'bar', items => [1, 2, 3] };
$cache->set('items', {}, $data);

my $cached = $cache->get('items', {});
is_deeply($cached, $data, 'Cached data matches');

# Test with params
my $data2 = { baz => 'qux' };
$cache->set('items', { id => 'test' }, $data2);

my $cached2 = $cache->get('items', { id => 'test' });
is_deeply($cached2, $data2, 'Cached data with params matches');

# Original cache still intact
my $cached_orig = $cache->get('items', {});
is_deeply($cached_orig, $data, 'Original cached data still matches');

# Test clear specific endpoint
$cache->clear('items');
is($cache->get('items', {}), undef, 'Endpoint cleared');

# Test clear all
$cache->set('items', {}, $data);
$cache->set('quests', {}, $data2);
$cache->clear;
is($cache->get('items', {}), undef, 'All cleared - items');
is($cache->get('quests', {}), undef, 'All cleared - quests');

# TTL: write the timestamp directly into the file instead of waiting
{
    my $dir = tempdir(CLEANUP => 1);
    my $c = WWW::ARDB::Cache->new(cache_dir => $dir, max_age => 100);

    my $file = $c->_cache_file('items', {});
    my $set_age = sub {
        my ($age) = @_;
        $c->set('items', {}, $data);
        my $entry = decode_json($file->slurp_utf8);
        $entry->{timestamp} = time() - $age;
        $file->spew_utf8(encode_json($entry));
    };

    $set_age->(10);
    is_deeply($c->get('items', {}), $data, 'entry inside the TTL is a hit');

    $set_age->(1000);
    is($c->get('items', {}), undef, 'entry outside the TTL is a miss');

    $set_age->(0);
    is(WWW::ARDB::Cache->new(cache_dir => $dir, max_age => 0)->get('items', {}),
        undef, 'max_age 0 never hits');

    for my $bad (
        [ 'no timestamp'      => sub { delete $_[0]{timestamp} } ],
        [ 'bad timestamp'     => sub { $_[0]{timestamp} = 'yesterday' } ],
        [ 'future timestamp'  => sub { $_[0]{timestamp} = time() + 1000 } ],
    ) {
        $c->set('items', {}, $data);
        my $entry = decode_json($file->slurp_utf8);
        $bad->[1]->($entry);
        $file->spew_utf8(encode_json($entry));
        is($c->get('items', {}), undef, $bad->[0] . ' is a miss');
    }

    $c->set('items', {}, $data);
    $file->spew_utf8(substr($file->slurp_utf8, 0, 20));
    is($c->get('items', {}), undef, 'truncated file is a miss');
}

done_testing;
