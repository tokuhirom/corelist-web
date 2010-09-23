use strict;
use warnings;

package Tripel;
use Text::Xslate;
use Router::Simple::Sinatraish ();
use File::Basename;
use File::Spec;

our $VERSION='0.02';

sub import {
    my $caller = caller(0);
    my $app_path = dirname([caller(0)]->[1]);
    my %xslates;

    Router::Simple::Sinatraish->export_to_level(1);

    no strict 'refs';
    *{"${caller}::xslate"}       = sub { $xslates{$caller} };
    *{"${caller}::res"}          = sub { Tripel::Response->new(@_) };
    *{"${caller}::to_app"}  = sub {
        # setup
        $xslates{$caller} = Text::Xslate->new(
            syntax => 'TTerse',
            path => [ File::Spec->catfile($app_path, 'tmpl') ]
        );

        sub {
            my $env = shift;
            if ( my $route = $caller->router->match($env) ) {
                my $c = Tripel::Context->new(env => $env, 'caller' => $caller, app_path => $app_path);
                my $res = $route->{code}->($c, $route);
                return $res->finalize();
            }
            else {
                my $content = 'not found';
                return [404, ['Content-Length' => length($content)], [$content]];
            }
        }
    };
}

package Tripel::Context;
use Mouse;
use HTML::FillInForm::Lite;
use Encode qw/encode_utf8/;

has env => ( is => 'ro', isa => 'HashRef', required => 1 );
has req => (
    is      => 'ro',
    isa     => 'Tripel::Request',
    default => sub { Tripel::Request->new( $_[0]->env ) }
);
has caller => (is => 'ro', isa => 'Str', required => 1);
has app_path => (is => 'ro', isa => 'Str', required => 1);
has fdat => (is => 'rw', isa => 'Any');

sub xslate { shift->caller->xslate }

sub render_with_fillin_form {
    my ($self, $tmpl, $args, $fdat) = @_;
    my $html = $self->xslate->render($tmpl, $args);
       $html = HTML::FillInForm::Lite->fill( \$html, $fdat );
    return $self->make_html_response($html);
}
sub render {
    my $self = shift;
    my $html = $self->xslate->render(@_);
    return $self->make_html_response($html);
}

sub make_html_response {
    my ($self, $html) = @_;
    $html = encode_utf8($html);
    return Tripel::Response->new(
        200,
        [
            'Content-Type'   => 'text/html; charset=utf-8',
            'Content-Length' => length($html)
        ],
        [$html]
    );
}

no Mouse;
__PACKAGE__->meta->make_immutable;

package Tripel::Request;
use parent qw/Plack::Request/;

package Tripel::Response;
use parent qw/Plack::Response/;
1;
