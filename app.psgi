use strict;
use warnings;
use 5.12.0;
use File::Basename;
use Cwd;
use lib Cwd::abs_path(dirname(__FILE__));
use Tripel;

use Module::CoreList;

our $VERSION = '0.02';

get '/api/v1/perl/list.{format:json}' => sub {
    my ($c, $p) = @_;
    return $c->render_json(
        {
            versions => [
                map { +{ version => $_ } }
                  reverse sort keys %Module::CoreList::version
            ]
        }
    );
};

get '/api/v1/perl/{version}.{format:json}' => sub {
    my ($c, $p) = @_;
    my @modules =
      map { +{ module => $_, version => $Module::CoreList::version{$p->{version}}->{$_} } }
      sort keys %{ $Module::CoreList::version{$p->{version}} };

    return $c->render_json(
        {
            version => $p->{version},
            modules => \@modules,
        }
    );
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
            first_release => Module::CoreList->first_release( $p->{module} ) || undef,
            module        => $p->{module}
        }
    );
};

# -------------------------------------------------------------------------

sub p { require Data::Dumper; print STDERR Data::Dumper::Dumper(@_) }

get '/' => sub {
    my ($c) = @_;

    my $q = $c->req->param('q') // 'Module::CoreList';
    my $res = $c->call("/api/v1/module/$q.json");
    $c->render( 'index.mustache', $res );
};

get '/version-list' => sub {
    my ($c) = @_;
    my $res = $c->call("/api/v1/perl/list.json");
    $c->render( 'version-list.mustache', $res );
};

get '/v/{version}' => sub {
    my ($c, $p) = @_;
    my $res = $c->call("/api/v1/perl/$p->{version}.json");

    $c->render('version.mustache', $res);
};

get '/m/:module' => sub {
    my ($c, $p) = @_;

    my $res = $c->call("/api/v1/module/$p->{module}.json");

    $c->render('module.mustache', $res);
};

use JSON;
sub Tripel::Context::call {
    my ($self, $endpoint) = @_;
    my $res = __PACKAGE__->to_app()->({
        REQUEST_URI => $endpoint,
        PATH_INFO   => $endpoint,
        map { $_ => $self->env->{$_} } qw/HTTP_HOST HTTP_USER_AGENT REQUEST_METHOD SCRIPT_NAME/
    });
    if ($res->[0] eq '200') {
        return decode_json($res->[2]->[0]);
    } else {
        return;
    }
}

to_app();

