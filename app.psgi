use strict;
use warnings;
use 5.010001;
use File::Basename;
use Amon2::Lite;
use version;

use Module::CoreList;

our $VERSION = '0.02';

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

    $c->render(
        'index.tt', {
            corelist_version => $Module::CoreList::VERSION,
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

