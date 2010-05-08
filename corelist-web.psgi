use strict;
use warnings;
use 5.12.0;
use Plack::Runner;
use Module::CoreList;
use Data::Section::Simple qw/get_data_section/;
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
            $params{mmm} = Text::Xslate::escaped_string(
                join "\n",
                map {
                    sprintf( q{<tr><td align="left">%s</td><td>%s</td></tr>},
                        $_, $modules{$_} // '' )
                  } sort keys %modules
            );
        }
    }
    if (my $q = $req->param('q')) {
        $params{q} = $q;
        $params{first_release} = Module::CoreList->first_release($q);
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

