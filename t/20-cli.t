#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Capture::Tiny qw( capture );
use lib 't/lib';
use MockUA;
use WWW::ARDB;

# Test module loading
use_ok('WWW::ARDB::CLI');
use_ok('WWW::ARDB::CLI::Cmd::Items');
use_ok('WWW::ARDB::CLI::Cmd::Item');
use_ok('WWW::ARDB::CLI::Cmd::Quests');
use_ok('WWW::ARDB::CLI::Cmd::Quest');
use_ok('WWW::ARDB::CLI::Cmd::Enemies');
use_ok('WWW::ARDB::CLI::Cmd::Enemy');

# Test CLI instantiation (reset @ARGV to avoid option parsing issues)
{
    local @ARGV = ();
    my $cli = WWW::ARDB::CLI->new;
    isa_ok($cli, 'WWW::ARDB::CLI');
    isa_ok($cli->api, 'WWW::ARDB');
}

# Test with options
{
    local @ARGV = ('--debug', '--no-cache', '--json');
    my $cli = WWW::ARDB::CLI->new;
    is($cli->debug, 1, 'debug option');
    is($cli->no_cache, 1, 'no_cache option');
    is($cli->json, 1, 'json option');
}

# Test default execute shows help
{
    local @ARGV = ();
    my $cli = WWW::ARDB::CLI->new;
    my ($stdout, $stderr) = capture {
        $cli->execute([], [$cli]);
    };
    like($stdout, qr/ardb - ARC Raiders Database CLI/, 'help header');
    like($stdout, qr/items/, 'help shows items command');
    like($stdout, qr/quests/, 'help shows quests command');
    like($stdout, qr/enemies/, 'help shows enemies command');
}

# Injected client: commands run offline against the fixtures
my $mock_api = WWW::ARDB->new( ua => MockUA->new, use_cache => 0 );

subtest 'injected api is used by the cli' => sub {
    local @ARGV = ();
    my $cli = WWW::ARDB::CLI->new( api => $mock_api );
    is( $cli->api, $mock_api, 'api constructor argument is returned as is' );
};

subtest 'items command against fixtures' => sub {
    local @ARGV = ();
    my $cli = WWW::ARDB::CLI->new( api => $mock_api );
    my ($stdout) = capture {
        WWW::ARDB::CLI::Cmd::Items->new->execute( [], [ $cli ] );
    };
    like( $stdout, qr/Acoustic Guitar\s+legendary\s+quick use\s+7000/, 'list row' );
    like( $stdout, qr/\n5 items found\./, 'item count' );

    ($stdout) = capture {
        WWW::ARDB::CLI::Cmd::Items->new( rarity => 'LEGENDARY' )->execute( [], [ $cli ] );
    };
    like( $stdout, qr/Acoustic Guitar/, 'client-side rarity filter keeps match' );
    unlike( $stdout, qr/\bWires\b/, 'client-side rarity filter drops others' );
};

subtest 'item command against fixtures' => sub {
    local @ARGV = ();
    my $cli = WWW::ARDB::CLI->new( api => $mock_api );
    my ($stdout) = capture {
        WWW::ARDB::CLI::Cmd::Item->new->execute( ['acoustic_guitar'], [ $cli ] );
    };
    like( $stdout, qr/^Acoustic Guitar$/m, 'item name' );
    like( $stdout, qr/Weight:?\s+1\b/, 'detail field from item fixture' );
    like( $stdout, qr/Wires/, 'breakdown component' );
};

subtest 'items command json output' => sub {
    local @ARGV = ('--json');
    my $cli = WWW::ARDB::CLI->new( api => $mock_api );
    my ($stdout) = capture {
        WWW::ARDB::CLI::Cmd::Items->new->execute( [], [ $cli ] );
    };
    like( $stdout, qr/^\[\{.*"id":"acoustic_guitar"/, 'json list' );
};

done_testing;
