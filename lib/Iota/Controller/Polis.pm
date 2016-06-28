package Iota::Controller::Polis;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );
use utf8;
use JSON::XS;

sub acoes : Local : Args(0) {
    my ( $self, $c ) = @_;

    my @list = $c->model('DB::Network')->search( undef, { order_by => 'name' } )->as_hashref->all;
    my @objs;

    foreach my $obj (@list) {
        push @objs, {
            (
                map { $_ => $obj->{$_} }
                  qw(
                  id name name_url template_name axis_name description text_content tags
                  )
            )
        };
    }

    $self->status_ok( $c, entity => { acoes => \@objs } );
}

sub acoes_item : Local : Args(1) {
    my ( $self, $c, $id ) = @_;

    my $item = $c->model('DB::Network')->search( { name_url => $id }, { order_by => 'name' } )->as_hashref->next;

    $self->status_not_found($c) unless $item;

    $item = {
        (
            map { $_ => $item->{$_} }
              qw(
              id name name_url template_name axis_name description text_content tags
              )
        )
    };

    $self->status_ok( $c, entity => $item );
}

sub acoes_search_get_ids : Local : Args(0) {
    my ( $self, $c ) = @_;

    my @ids = $c->model('DB::Network')->search(
        { indexable_text => \[ "@@ plainto_tsquery('pg_catalog.portuguese', ?)", $c->req->params->{q} ] },
        {
            order_by => [

                \[ "TS_RANK_CD(indexable_text, plainto_tsquery('pg_catalog.portuguese', ?))", $c->req->params->{q} ]
              ]
            ,
            columns => [qw/id/]
        }
    )->as_hashref->all;

    $self->status_ok( $c, entity => { ids => \@ids } );
}

__PACKAGE__->meta->make_immutable;

1;
