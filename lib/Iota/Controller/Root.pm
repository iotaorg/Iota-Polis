package Iota::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

=head1 NAME

Iota::Controller::Root - Root Controller for Iota

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->res->body('{"perl":"awesome!"}');
}

sub root : Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

}

sub default : Path {
    my ( $self, $c ) = @_;

    $c->res->status(404);
    $c->res->body('resource not found');
}

sub error_404_rdf : Private {
    my ( $self, $c, $foo ) = @_;
    $c->res->status(404);
    $c->res->body('resource not found');
}

sub error_404 : Private {
    my ( $self, $c, $foo ) = @_;

    $c->res->status(404);
    $c->res->body('resource not found');
}

sub error_500 : Private {
    my ( $self, $c, $arg ) = @_;
    $c->response->body( $arg || 'error' );
    $c->response->status(500);

}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;

}

=head1 AUTHOR

Thiago Rondon

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
