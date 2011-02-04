use strict;
use warnings;
use utf8;
use Test::More;
use Test::WWW::Mechanize::PSGI;
use Plack::Util;
use JSON;

my $app = Plack::Util::load_psgi 'corelist-web.psgi';
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);

$mech->get_ok('/api/v1/perl/list.json');
note $mech->content;
is ref decode_json($mech->content), 'ARRAY';

$mech->get_ok('/api/v1/perl/5.006001.json');
note $mech->content;
is ref decode_json($mech->content), 'HASH';

$mech->get_ok('/api/v1/module/Encode.json');
note $mech->content;
is ref decode_json($mech->content), 'HASH';

done_testing;

