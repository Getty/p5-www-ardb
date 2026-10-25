requires 'Digest::MD5';
requires 'HTTP::Request';
requires 'JSON::MaybeXS';
requires 'LWP::UserAgent';
requires 'Moo';
requires 'MooX::Cmd';
requires 'MooX::Options';
requires 'Path::Tiny';
requires 'Types::Standard';
requires 'URI';
requires 'namespace::clean';

on test => sub {
    requires 'Capture::Tiny';
    requires 'Test::More';
};
