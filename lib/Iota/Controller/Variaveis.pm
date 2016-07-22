package Iota::Controller::Variaveis;
use Moose;

BEGIN { extends 'Catalyst::Controller::REST' }
__PACKAGE__->config( default => 'application/json' );
use utf8;
use JSON::XS;

use File::Basename;
use XML::Simple qw(:strict);

sub _period_pt {
    my ( $self, $period ) = @_;

    return 'semanal' if $period eq 'weekly';
    return 'mensal'  if $period eq 'monthly';
    return 'anual'   if $period eq 'yearly';
    return 'decada'  if $period eq 'decade';
    return 'diario'  if $period eq 'daily';

    return $period;    # outros nao usados
}

sub ymd2dmy {
    my ( $self, $str ) = @_;
    return "$3/$2/$1" if ( $str =~ /(\d{4})-(\d{2})-(\d{2})/ );
    return '';
}

sub download_variables : Chained('/') PathPart('api/download-variables') Args(0) ActionClass('REST') {

}

sub download_variables_GET {
    my ( $self, $c ) = @_;
    my $params = $c->req->params;
    my @objs;

    my $data_rs =
      $c->model( 'DB::ViewDownloadVariablesRegion' )
      ->search( {}, { result_class => 'DBIx::Class::ResultClass::HashRefInflator' } );

    if ( exists $params->{user_id} ) {
        my @ids = split /,/, $params->{user_id};

        $self->status_bad_request( $c, message => 'invalid user_id' ), $c->detach
          unless Iota::Controller::Dados::int_validation( $self, @ids );

        $data_rs = $data_rs->search( { user_id => { 'in' => \@ids } } );
    }

    if ( exists $params->{city_id} ) {
        my @ids = split /,/, $params->{city_id};

        $self->status_bad_request( $c, message => 'invalid city_id' ), $c->detach
          unless Iota::Controller::Dados::int_validation( $self, @ids );

        $data_rs = $data_rs->search( { city_id => { 'in' => \@ids } } );
    }

    if ( exists $params->{variable_id} ) {
        my @ids = split /,/, $params->{variable_id};

        $self->status_bad_request( $c, message => 'invalid variable_id' ), $c->detach
          unless Iota::Controller::Dados::int_validation( $self, @ids );

        $data_rs = $data_rs->search( { variable_id => { 'in' => \@ids } } );
    }

    if ( exists $params->{indicator_id} ) {
        my @ids = split /,/, $params->{indicator_id};

        $self->status_bad_request( $c, message => 'invalid indicator_id' ), $c->detach
          unless Iota::Controller::Dados::int_validation( $self, @ids );

        $data_rs = $data_rs->search(
            {
                variable_id => {
                    'in' => [
                        map { $_->{variable_id} } $c->model('DB::IndicatorVariable')->search(
                            { indicator_id => { 'in' => \@ids } },
                            { result_class => 'DBIx::Class::ResultClass::HashRefInflator' }
                        )
                    ]->all
                }
            }
        );
    }

    if ( exists $params->{valid_from} ) {
        my @dates = split /,/, $params->{valid_from};

        $self->status_bad_request( $c, message => 'invalid date format' ), $c->detach
          unless Iota::Controller::Dados::date_validation( $self, @dates );

        $data_rs = $data_rs->search( { valid_from => { 'in' => \@dates } } );
    }

    if ( exists $params->{valid_from_begin} ) {

        $self->status_bad_request( $c, message => 'invalid date format' ), $c->detach
          unless Iota::Controller::Dados::date_validation( $self, $params->{valid_from_begin} );

        $data_rs = $data_rs->search( { valid_from => { '>=' => $params->{valid_from_begin} } } );
    }

    if ( exists $params->{valid_from_end} ) {

        $self->status_bad_request( $c, message => 'invalid date format' ), $c->detach
          unless Iota::Controller::Dados::date_validation( $self, $params->{valid_from_end} );

        $data_rs = $data_rs->search( { '-and' => { valid_from => { '<=' => $params->{valid_from_end} } } } );
    }

    while ( my $row = $data_rs->next ) {
        $row->{period}     = $self->_period_pt( $row->{period} );
        $row->{valid_from} = $self->ymd2dmy( $row->{valid_from} );
        push @objs, $row;
    }

    $self->status_ok( $c, entity => { data => \@objs } );
}

1;
