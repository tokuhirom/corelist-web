use strict;
use warnings;
use 5.12.0;
use File::Basename;
use lib dirname(__FILE__);
use Tripel;

use Module::CoreList;

our $VERSION = '0.01';

get '/' => sub {
    my ($c) = @_;

    my $q = $c->req->param('q') // 'Module::CoreList';
    $c->render( 'index.tt',
        { q => $q, first_release => Module::CoreList->first_release($q) } );
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
    my @data;
    for my $v (reverse sort keys %Module::CoreList::version) {
        my $modver = $Module::CoreList::version{$v}->{$module};
        next unless $modver;
        push @data, {perl => $v, module => $modver};
    }

    $c->render('module.tt', {data => \@data, module => $module});
};

to_app();

