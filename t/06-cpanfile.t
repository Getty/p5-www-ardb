#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Module::CoreList;
use Path::Tiny qw( path );

# Every module loaded by lib/ and bin/ must be declared in the cpanfile.
# Core modules and the distribution's own namespace need no declaration.

my $root = path(__FILE__)->parent->parent;

my %declared = map { $_ => 1 }
    $root->child('cpanfile')->slurp_utf8 =~ /^\s*requires\s+'([^']+)'/mg;

my %used;
my @files;
my $iter = $root->child('lib')->iterator({ recurse => 1 });
while (my $f = $iter->()) {
    push @files, $f if $f->is_file && $f->basename =~ /\.pm\z/;
}
push @files, $root->child('bin')->children;

for my $file (@files) {
    for my $line ($file->lines_utf8) {
        next unless $line =~ /^\s*(?:use|require)\s+([A-Za-z_][\w:]*)/;
        $used{$1} = 1;
    }
}

for my $module (sort keys %used) {
    next if $module =~ /\A(?:strict|warnings|utf8|feature|lib|parent|base|vars|constant)\z/;
    next if $module =~ /\AWWW::ARDB(?:::|\z)/;
    next if defined Module::CoreList->first_release($module);
    ok($declared{$module}, $module . ' is declared in the cpanfile');
}

ok(scalar(keys %used) > 5, 'found use statements in lib/ and bin/');

done_testing;
