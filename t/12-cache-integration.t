#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use lib 't/lib';
use JSON::MaybeXS qw( encode_json decode_json );
use Path::Tiny qw( path );

use WWW::ARDB;
use MockUA;

{
    package CountingUA;
    use parent -norequire, 'MockUA';
    sub new { my $s = MockUA::new(@_); $s->{count} = 0; $s }
    sub request { $_[0]{count}++; MockUA::request(@_) }
}

my $tmpdir = tempdir(CLEANUP => 1);
my $mock_ua = MockUA->new(fixtures_dir => 't/fixtures');

# Test with caching enabled
my $api = WWW::ARDB->new(
    ua        => $mock_ua,
    use_cache => 1,
    cache_dir => $tmpdir,
);

# First call - should fetch
my $items1 = $api->items;
is(scalar @$items1, 5, 'first call returns items');

# Second call - should use cache
my $items2 = $api->items;
is(scalar @$items2, 5, 'second call returns same count');

# Verify cache files exist
ok(-d $tmpdir, 'cache dir exists');
my @files = glob("$tmpdir/*.json");
ok(scalar @files > 0, 'cache files created');

# Test clear_cache for specific endpoint
$api->clear_cache('items');
@files = glob("$tmpdir/default_items*.json");
is(scalar @files, 0, 'items cache cleared');

# Fetch quests to create cache
$api->quests;
@files = glob("$tmpdir/*.json");
ok(scalar @files > 0, 'quests cache created');

# Test clear_cache for all
$api->clear_cache;
@files = glob("$tmpdir/*.json");
is(scalar @files, 0, 'all cache cleared');

# Test with caching disabled
my $api_no_cache = WWW::ARDB->new(
    ua        => $mock_ua,
    use_cache => 0,
);

$api_no_cache->items;
@files = glob("$tmpdir/*.json");
is(scalar @files, 0, 'no cache created when disabled');

# Expired entries are fetched again and the file is rewritten
{
    my $dir = tempdir(CLEANUP => 1);
    my $counter = CountingUA->new;
    my $c_api = WWW::ARDB->new(
        ua             => $counter,
        cache_dir      => $dir,
        cache_max_age  => 100,
    );
    $c_api->items;
    $c_api->items;
    is($counter->{count}, 1, 'second call inside the TTL is served from the cache');

    my ($file) = glob("$dir/*.json");
    my $entry = decode_json(path($file)->slurp_utf8);
    $entry->{timestamp} = time() - 1000;
    path($file)->spew_utf8(encode_json($entry));

    $c_api->items;
    is($counter->{count}, 2, 'expired entry is fetched again');
    cmp_ok(decode_json(path($file)->slurp_utf8)->{timestamp}, '>', time() - 100,
        'cache file rewritten with a fresh timestamp');

    $c_api->items;
    is($counter->{count}, 2, 'refreshed entry is a hit again');

    my $fresh = WWW::ARDB->new(ua => $counter, cache_dir => $dir, cache_max_age => 0);
    $fresh->items;
    is($counter->{count}, 3, 'cache_max_age 0 always fetches');
}

done_testing;
