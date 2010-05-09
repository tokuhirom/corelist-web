use strict;
use warnings;
use 5.12.0;
use Plack::Runner;
use Module::CoreList;
use Plack::Request;
use Text::Xslate;
use Path::Class;
use Encode qw/encode_utf8/;

my $xslate = Text::Xslate->new(
    path  => [ file(__FILE__)->dir->file("tmpl") ],
    cache => 0
);

sub app {
    my $req = Plack::Request->new(shift);
    my %params;
    my $tmpl = 'index.tx';

    # main
    given ($req->env->{PATH_INFO}) {
        when ('/') {
            my $q = $req->param('q') // 'Module::CoreList';
            $params{q} = $q;
            $params{first_release} = Module::CoreList->first_release($q);
        }
        when ('/version-list') {
            $tmpl = 'version-list.tx';
            $params{versions} =
              [ reverse sort keys %Module::CoreList::version ];
        }
        when (m{^/v/(.+)$}) {
            $tmpl = 'version.tx';
            my $version = $1;
            $params{version} = $version;
            # $params{modules} = $Module::CoreList::version{$1};
            my %modules = %{$Module::CoreList::version{$version}};
            $params{module_keys} = [sort keys %modules];
            $params{modules} = \%modules;
        }
        when (m{^/m/(.+)$}) {
            my $module = $1;
            $params{module} = $module;
            $tmpl = 'module.tx';
            my @data;
            for my $v (reverse sort keys %Module::CoreList::version) {
                my $modver = $Module::CoreList::version{$v}->{$module};
                next unless $modver;
                push @data, {perl => $v, module => $modver};
            }
            $params{data} = \@data;
        }
    }

    my $content = $xslate->render($tmpl, \%params);
    $content = encode_utf8($content);
    return [200, ['Content-Length' => length($content)], [$content]];
}

if ($0 eq __FILE__) {
    my $runner = Plack::Runner->new();
    $runner->parse_options(@ARGV);
    $runner->run(\&app);
}

no warnings 'void';
\&app;

