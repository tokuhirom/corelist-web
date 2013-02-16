use strict;
use warnings;
use 5.010001;
use File::Basename;
use Amon2::Lite;
use version;

use Module::CoreList;

our $VERSION = '0.02';

__PACKAGE__->load_plugin('Web::JSON');

sub format_perl_version {
    my $v = shift;
    return version->new($v)->normal;
}

sub versions {
    my $module = shift;

    my @data;
    for my $v (reverse sort keys %Module::CoreList::version) {
        my $modver = $Module::CoreList::version{$v}->{$module};
        next unless $modver;
        push @data, {perl => $v, module => $modver};
    }
    return @data;
}

get '/' => sub {
    my ($c) = @_;

    my $q = $c->req->param('q') // 'Module::CoreList';

    my @releases = versions($q);

    $c->render(
        'index.tt', {
            q => $q,
            first_release => Module::CoreList->first_release($q),
            releases => \@releases,
        }
    );
};

get '/api/v1/perl/list.{format:json}' => sub {
    my ($c, $p) = @_;
    return $c->render_json([ reverse sort keys %Module::CoreList::version ]);
};

get '/api/v1/perl/{version}.{format:json}' => sub {
    my ($c, $p) = @_;
    return $c->render_json($Module::CoreList::version{$p->{version}});
};

get '/api/v1/module/{module}.{format:json}' => sub {
    my ($c, $p) = @_;

    my @data;
    for my $v (reverse sort keys %Module::CoreList::version) {
        my $modver = $Module::CoreList::version{$v}->{$p->{module}};
        next unless $modver;
        push @data, {perl => $v, module => $modver};
    }
    return $c->render_json(
        {
            releases      => \@data,
            first_release => Module::CoreList->first_release( $p->{dist} )
        }
    );
};

get '/version-list' => sub {
    my ($c) = @_;
    $c->render( 'version-list.tt',
        { versions => [ reverse sort keys %Module::CoreList::version ] } );
};

get '/v/{version}' => sub {
    my ($c, $args) = @_;
    my $version = $args->{version} // die;
    my %modules = %{$Module::CoreList::version{$version}};
    # $params{module_keys} = [sort keys %modules];
    $c->render('version.tt', {version => $version, modules => \%modules});
};

get '/m/:module' => sub {
    my ($c, $args) = @_;

    my $module = $args->{module} // die;
    my @data = versions($module);

    $c->render('module.tt', {data => \@data, module => $module});
};

__PACKAGE__->to_app();

