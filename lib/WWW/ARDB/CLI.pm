package WWW::ARDB::CLI;

# ABSTRACT: Command-line interface for WWW::ARDB

use Moo;
use MooX::Cmd;
use WWW::ARDB;
use JSON::MaybeXS qw( encode_json );
use Getopt::Long qw(:config pass_through);

our $VERSION = '0.002';

=head1 SYNOPSIS

    use WWW::ARDB::CLI;
    WWW::ARDB::CLI->new_with_cmd;

=head1 DESCRIPTION

Main CLI class for the ARC Raiders Database API client. Uses L<MooX::Cmd>
for subcommand handling.

See C<ardb --help> for command-line usage.

=cut

has debug => (
    is      => 'ro',
    default => sub { $ENV{WWW_ARDB_DEBUG} // 0 },
);

=attr debug

Boolean. Enable debug output. Set via C<--debug> or C<-d> flag, or
C<WWW_ARDB_DEBUG> environment variable. Defaults to C<0>.

=cut

has no_cache => (
    is      => 'ro',
    default => sub { $ENV{WWW_ARDB_NO_CACHE} // 0 },
);

=attr no_cache

Boolean. Disable response caching. Set via C<--no-cache> flag, or
C<WWW_ARDB_NO_CACHE> environment variable. Defaults to C<0>.

=cut

has json => (
    is      => 'ro',
    default => sub { $ENV{WWW_ARDB_JSON} // 0 },
);

=attr json

Boolean. Output results as JSON. Set via C<--json> or C<-j> flag, or
C<WWW_ARDB_JSON> environment variable. Defaults to C<0>.

=cut

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    my ($debug, $no_cache, $json);
    GetOptions(
        'debug|d'  => \$debug,
        'no-cache' => \$no_cache,
        'json|j'   => \$json,
    );

    my $result = $class->$orig(@args);
    $result->{debug}    = $debug    if $debug;
    $result->{no_cache} = $no_cache if $no_cache;
    $result->{json}     = $json     if $json;

    return $result;
};

has api => (
    is      => 'lazy',
    builder => '_build_api',
);

=attr api

L<WWW::ARDB> instance used for API calls. Automatically configured with
debug and caching settings.

=cut

sub _build_api {
    my $self = shift;
    return WWW::ARDB->new(
        debug     => $self->debug,
        use_cache => !$self->no_cache,
    );
}

sub execute {
    my ($self, $args, $chain) = @_;

    if (!@$chain || @$chain == 1) {
        print "ardb - ARC Raiders Database CLI\n\n";
        print "Usage: ardb <command> [options]\n\n";
        print "Commands:\n";
        print "  items     List all items\n";
        print "  item      Show item details\n";
        print "  quests    List all quests\n";
        print "  quest     Show quest details\n";
        print "  enemies   List all ARC enemies\n";
        print "  enemy     Show ARC enemy details\n";
        print "\nGlobal Options:\n";
        print "  -d, --debug     Enable debug output\n";
        print "  -j, --json      Output as JSON\n";
        print "  --no-cache      Disable caching\n";
        print "\nExamples:\n";
        print "  ardb items --search guitar\n";
        print "  ardb item acoustic_guitar\n";
        print "  ardb enemies\n";
        print "  ardb enemy wasp --json\n";
        print "\nData provided by ardb.app\n";
    }
}

sub output_json {
    my ($self, $data) = @_;
    print encode_json($data) . "\n";
}

=method output_json

    $cli->output_json($data);

Helper method to output data as JSON. Used by subcommands.

=cut

1;
