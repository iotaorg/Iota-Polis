
package Iota::Controller::API::UserPublic;

use Moose;
use Iota::IndicatorFormula;
use JSON qw(encode_json);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/root') : PathPart('public/user') : CaptureArgs(0) {
    my ( $self, $c ) = @_;


    $c->stash->{collection} = $c->model('DB::User');
}



sub object : Chained('base') : PathPart('') : CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    $self->status_bad_request( $c, message => 'invalid.argument' ), $c->detach
      unless $id =~ /^[0-9]+$/;

    $c->detach( '/error_500', ['user.id invalid!'] ) unless $id =~ /^[0-9]+$/;

    $c->stash->{user} = $c->stash->{collection}->search_rs(
        {
            id          => $id,
            'me.active' => 1
        }
    );

    $c->stash->{user_obj} = $c->stash->{user}->next;

    $c->detach('/error_404') unless defined $c->stash->{user_obj};

    my @networks = $c->stash->{user_obj}->networks->all;
    $c->detach('/error_404') unless @networks;

    $c->stash->{networks} = \@networks;

    $c->stash->{user_id} = int $id;
}

sub user : Chained('object') : PathPart('') : Args(0) : ActionClass('REST') {
    my ( $self, $c ) = @_;

}

=pod


Retorna as informações das ultimas versoes das variveis basicas, cidade, foto da capa,

GET /api/public/user/$id

Retorna:

    {
        variaveis => [{
            nome => '',
            valor => '',
            data => ''
        }],
        cidade => {
            pais, uf, cidade, latitude, longitude
        },

    }

=cut

sub user_public_load {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user_obj};

    my $ret = {};
    do {
        my $rs = $c->model('DB::Variable')->search_rs(
            {
                'values.user_id' => $user->id,
                is_basic         => 1
            },
            { prefetch => [ 'values', 'measurement_unit' ] }
        );

        $rs = $rs->as_hashref;
        my $existe = {};
        while ( my $r = $rs->next ) {

            @{ $r->{values} } = map { $_ } sort { $a->{valid_from} cmp $b->{valid_from} } @{ $r->{values} };
            my $valor = pop @{ $r->{values} };

            push(
                @{ $ret->{variaveis} },
                {
                    name                  => $r->{name},
                    cognomen              => $r->{cognomen},
                    period                => $r->{period},
                    type                  => $r->{type},
                    measurement_unit      => $r->{measurement_unit}{short_name},
                    measurement_unit_name => $r->{measurement_unit}{name},
                    last_value            => $valor->{value},
                    last_value_date       => $valor->{valid_from}
                }
            );
        }

    };

    do {
        my $r = $c->model('DB::City')->search_rs( { 'id' => $user->city_id } )->as_hashref->next;

        if ($r) {

            $ret->{cidade} = {
                name                        => $r->{name},
                uf                          => $r->{uf},
                pais                        => $r->{pais},
                latitude                    => $r->{latitude},
                longitude                   => $r->{longitude},
                telefone_prefeitura         => $r->{telefone_prefeitura},
                endereco_prefeitura         => $r->{endereco_prefeitura},
                bairro_prefeitura           => $r->{bairro_prefeitura},
                cep_prefeitura              => $r->{cep_prefeitura},
                nome_responsavel_prefeitura => $r->{nome_responsavel_prefeitura},
                email_prefeitura            => $r->{email_prefeitura},

                # summary                     => $r->{summary},
            };
        }

    };

    do {
        my $r = $c->model('DB::Region')->search_rs( { 'id' => $c->req->params->{region_id} } )->as_hashref->next;

        if ($r) {

            $ret->{region} = {
                name     => $r->{name},
                name_url => $r->{name_url}
            };
        }

    } if exists $c->req->params->{region_id};

    $ret->{usuario} = {
        files => {
            map { $_->class_name => $_->public_url } $user->user_files->search(
                {
                    hide_listing => 1
                },
                { order_by => 'created_at' }
            )
        },
        city_summary => $user->city_summary
    };

    return $ret;
}

sub user_GET {
    my ( $self, $c ) = @_;

    my $ret = $self->user_public_load($c);
    $self->status_ok( $c, entity => $ret );
}

1;

