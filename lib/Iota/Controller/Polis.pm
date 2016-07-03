package Iota::Controller::Polis;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );
use utf8;
use JSON::XS;
use Encode;

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

    my $q = lc( $c->req->params->{q} || '' );

    my ($eixo) = $q =~ s/\s*eixo\s(\d+)\s*// && $1;

    my ( $search, $order );
    if ( $q !~ /\s/ && $q ) {
        $search = {
            '-or' => [
                \[ "lower(unaccent(me.name)) ilike unaccent(?)",        [ q => "%$q%" ] ],
                \[ "lower(unaccent(me.description)) ilike unaccent(?)", [ q => "%$q%" ] ],
                \[ "lower(unaccent(me.tags)) ilike unaccent(?)",        [ q => "%$q%" ] ],
            ]
        };
    }
    else {
        if ($q) {
            $search = {
                '-or' => [
                    \[ "lower(unaccent(me.name)) ilike unaccent(?)",        [ q => "%$q%" ] ],
                    \[ "lower(unaccent(me.description)) ilike unaccent(?)", [ q => "%$q%" ] ],
                    \[ "lower(unaccent(me.tags)) ilike unaccent(?)",        [ q => "%$q%" ] ],
                    indexable_text => \[ "@@ plainto_tsquery('pg_catalog.portuguese', unaccent(?))", $q ]
                ],

            };
            $order = {
                order_by => [
                    \[
                        "TS_RANK_CD(indexable_text, plainto_tsquery('pg_catalog.portuguese', unaccent(?)))",
                        $c->req->params->{q}
                    ]
                ],
                columns => [qw/id/]
            };
        }
    }

    $search->{axis_name} = { 'ilike' => "eixo $eixo%" } if $eixo;

    my @ids = map { $_->{id} } $c->model('DB::Network')->search( $search, $order )->as_hashref->all;

    $self->status_ok( $c, entity => { ids => \@ids } );
}

sub menus : Local : Args(0) {
    my ( $self, $c, ) = @_;

    my @menus = $c->model('DB::UserMenu')->search(
        undef,
        {
            order_by     => [ { -desc => 'menu_id' }, 'position' ],
            prefetch     => 'page',
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all;

    $self->status_ok( $c, entity => { menus => \@menus } );
}

sub indicadores_acao : Local : Args(1) {
    my ( $self, $c, $acao_id ) = @_;

    my @indicators = $c->model('DB::Indicator')->search(
        { 'indicator_network_visibilities.network_id' => $acao_id },
        {
            join    => ['indicator_network_visibilities'],
            columns => [
                qw /id name name_url variable_type /,
                { 'reservado'         => \'goal_explanation as reservado' },
                { 'descricao_formula' => \'explanation as descricao_formula' },
                { 'nossa_leitura'     => \'observations as nossa_leitura' },
            ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            order_by     => 'name'
        }
    )->all;

    $self->status_ok( $c, entity => { indicators => \@indicators } );
}

sub _limpa_ano {
    substr( shift, 0, 4 );
}

sub indicador_tabela_rot_regiao : Local : Args(1) {
    my ( $self, $c, $indicador_id ) = @_;

    my $indicador = $c->model('DB::Indicator')->search(
        {
            id            => $indicador_id,
            variable_type => { '!=' => 'str' }
        }
    )->next;
    die "not found\n" unless $indicador;

    my $rs = $c->model('DB::IndicatorValue')->search(
        { 'indicator_id' => $indicador_id, },
        {
            join         => [],
            columns      => [ qw /region_id value valid_from/, ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    );
    my $rot = {};
    my %lines;
    while ( my $r = $rs->next ) {
        $rot->{ $r->{valid_from} }{ $r->{region_id} } = $r->{value};
        $lines{ $r->{valid_from} } = 1;
    }

    my @headers = map { { k => $_->{id}, v => $_->{name} } } $c->model('DB::Region')->search(
        {
            id => {
                in => [
                    351,     35063,   3537602, 3522109, 3531100, 3541000, 3551009, 3548500,
                    3513504, 3518701, 3506359, 35054,   3550704, 3520400, 3510500, 3555406,
                ]
            }
        },
        {
            columns      => [qw/name id/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            order_by     => [ { -desc => 'depth_level' }, 'upper_region', 'name' ]
        }
    )->all;

    my @lines = sort { $a->{k} cmp $b->{k} } map { { k => $_, v => &_limpa_ano($_) } } keys %lines;

    $self->status_ok( $c, entity => { data => $rot, headers => \@headers, lines => \@lines } );
}

sub indicador_tabela_rot_txt : Local : Args(1) {
    my ( $self, $c, $indicador_id ) = @_;

    my $indicador = $c->model('DB::Indicator')->search(
        {
            id            => $indicador_id,
            variable_type => 'str'
        }
    )->next;
    die "not found\n" unless $indicador;

    my $rs = $c->model('DB::IndicatorValue')->search(
        {
            'indicator_id' => $indicador_id,
            valid_from     => '2000-01-01', # por enquanto só vamos usar ano 2000 para essas variaveis
        },
        {
            join         => [],
            columns      => [ qw /region_id values_used valid_from/, ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        }
    );
    my $rot = {};
    while ( my $r = $rs->next ) {
        my $values = decode_json( encode 'utf8', $r->{values_used} );
        while ( my ( $variable_id, $value ) = each %$values ) {
            $rot->{ $r->{region_id} }{$variable_id} = $value;
        }
    }

    my @lines = map { { k => $_->{id}, v => $_->{name} } } $c->model('DB::Region')->search(
        {
            id => {
                in => [
                    3537602, 3522109, 3531100, 3541000, 3551009, 3548500, 3513504, 3518701,
                    3506359, 3550704, 3520400, 3510500, 3555406,
                ]
            }
        },
        {
            columns      => [qw/name id/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            order_by     => [ { -desc => 'depth_level' }, 'upper_region', 'name' ]
        }
    )->all;

    my ( $formula, @variables_id ) = ( $indicador->formula );
    push @variables_id, $1 while ( $formula =~ /\$(\d+)\b/go );

    my @headers = map { { k => $_->{id}, v => $_->{cognomen}, name => $_->{name}, c => $_->{colors} } } $c->model('DB::Variable')->search(
        { id => { in => \@variables_id } },
        {
            columns      => [qw/name cognomen id colors/],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all;

    my %variable_colors;
    foreach my $v (@headers){
        my $c = delete $v->{c};
        if($c){
            $c=  decode_json ( encode 'utf8', $c);
            $variable_colors{$v->{k}} = $c;
        }
    }

    $self->status_ok( $c, entity => { data => $rot, headers => \@headers, lines => \@lines, variable_colors=>\%variable_colors } );
}

__PACKAGE__->meta->make_immutable;

1;
