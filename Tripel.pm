use strict;
use warnings;

package Tripel;
use Text::Xslate;
use Router::Simple::Sinatraish ();
use File::Basename;
use File::Spec;
use 5.008001;

our $VERSION='0.04';

our $CONTEXT;

sub import {
    my $caller = caller(0);
    my $app_path = dirname([caller(0)]->[1]);

    Router::Simple::Sinatraish->export_to_level(1);

    no strict 'refs';
    *{"${caller}::res"}          = sub { Tripel::Response->new(@_) };
    *{"${caller}::to_app"}  = sub {
        # setup
        my $xslate = Text::Xslate->new(
            syntax => 'TTerse',
            path => [ File::Spec->catfile($app_path, 'tmpl') ],
            module => ['Text::Xslate::Bridge::TT2Like'],
        );
        my $config = do {
            my $env = $ENV{PLACK_ENV} || 'development';
            my $conf = File::Spec->catfile($app_path, 'config', "$env.pl");
            if (-f $conf) {
                do $conf;
            } else {
                +{ }; # empty configuration
            }
        };

        my $app = sub {
            my $env = shift;
            if ( my $route = $caller->router->match($env) ) {
                my $c = Tripel::Context->new(env => $env, 'caller' => $caller, app_path => $app_path, config => $config, tmpl => $xslate);
                local $CONTEXT = $c;
                my $res = $route->{code}->($c, $route);
                return $res->finalize();
            }
            else {
                my $content = 'not found';
                return [404, ['Content-Length' => length($content)], [$content]];
            }
        };
        return $app;
    };
}

package Tripel::Context;
use Mouse;
use HTML::FillInForm::Lite;
use Encode qw/encode_utf8/;
use JSON;

has req => (
    is      => 'ro',
    isa     => 'Tripel::Request',
    lazy    => 1,
    default => sub { Tripel::Request->new( $_[0]->env ) }
);
has env      => ( is => 'ro', isa => 'HashRef', required => 1 );
has caller   => ( is => 'ro', isa => 'Str',     required => 1 );
has app_path => ( is => 'ro', isa => 'Str',     required => 1 );
has config   => ( is => 'ro', isa => 'HashRef', required => 1 );
has tmpl     => ( is => 'ro', isa => 'Object',  required => 1 )
  ;    # any object supports Tiffany protocol

sub render_with_fillin_form {
    my ($self, $tmpl, $args, $fdat) = @_;
    my $html = $self->tmpl->render($tmpl, $args);
       $html = HTML::FillInForm::Lite->fill( \$html, $fdat );
    return $self->make_html_response($html);
}
sub render {
    my $self = shift;
    my $html = $self->tmpl->render(@_);
    return $self->make_html_response($html);
}

sub render_json {
    my ($self, $stuff) = @_;

    my $json = encode_json($stuff);
    return Tripel::Response->new(
        200,
        [
            'Content-Length' => length($json),
            'Content-Type'   => 'application/json; charset=utf-8'
        ],
        [$json]
    );
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

sub body_parameters {
    my ($self) = @_;
    $self->{'amon2.body_parameters'} ||= $self->_decode_parameters($self->SUPER::body_parameters());
}

sub query_parameters {
    my ($self) = @_;
    $self->{'amon2.query_parameters'} ||= $self->_decode_parameters($self->SUPER::query_parameters());
}

my $encoding = Encode::find_encoding('utf-8');
sub _decode_parameters {
    my ($self, $stuff) = @_;

    my @flatten = $stuff->flatten();
    my @decoded;
    while ( my ($k, $v) = splice @flatten, 0, 2 ) {
        push @decoded, Encode::decode($encoding, $k), Encode::decode($encoding, $v);
    }
    return Hash::MultiValue->new(@decoded);
}

package Tripel::Response;
use parent qw/Plack::Response/;
1;
__END__

=head1 DESCRIPTION

This is one file tiny web application framework.

=head1 CONCEPT OF Tripel

=over 4

=item Depend to Xslate

tokuhirom loves Xslate + TTerse syntax

=item One file framework

like web.py

=item Simple and Thin

=back

=head1 AUTHOR

Tokuhiro Matsuno(tokuhirom)

=head1 LICENSE

Copyright (c) 2010, Tokuhiro Matsuno(tokuhirom). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
