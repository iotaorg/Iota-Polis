package Iota::Controller::Web;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
use utf8;
use JSON::XS;
use Iota::Statistics::Frequency;
use I18N::AcceptLanguage;
use DateTime;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config( namespace => '' );

has 'lang_acceptor' => (
    is      => 'rw',
    isa     => 'I18N::AcceptLanguage',
    lazy    => 1,
    default => sub { I18N::AcceptLanguage->new( defaultLanguage => 'pt-br' ) }
);

sub change_lang : Chained('root') PathPart('lang') CaptureArgs(1) {
    my ( $self, $c, $lang ) = @_;
    $c->stash->{lang} = $lang;
}

sub change_lang_redir : Chained('change_lang') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $cur_lang = $c->stash->{lang};
    my %langs = map { $_ => 1 } split /,/, $c->config->{available_langs};
    $cur_lang = 'pt-br' unless exists $langs{$cur_lang};
    my $host = $c->req->uri->host;

    $c->response->cookies->{'cur_lang'} = {
        value   => $cur_lang,
        path    => '/',
        expires => '+3600h',
    };

    my $refer = $c->req->headers->referer;
    if ( $refer && $refer =~ /^http:\/\/$host/ ) {
        $c->res->redirect($refer);
    }
    else {
        $c->res->redirect( $c->uri_for('/') );
    }
    $c->detach;
}

sub institute_load : Chained('root') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # se veio ?part, guarda na stash e remove ele da req para nao atrapalhar novas geracoes de URLs
    $c->stash->{current_part} = delete $c->req->params->{part};
    if ( $c->stash->{current_part} ) {
        delete $c->req->{query_parameters}{part};
        $c->req->uri( $c->req->uri_with( { part => undef } ) );
    }

    my $domain = $c->req->uri->host;
    my $net = $c->model('DB::Network')->search( { domain_name => $domain } )->first;

    if ( exists $ENV{HARNESS_ACTIVE} && $ENV{HARNESS_ACTIVE} ) {
        $net = $c->model('DB::Network')->search( { institute_id => 1 } )->first;
    }

    $c->detach( '/error_404', [ 'Nenhuma rede para o dominio ' . $domain . '!' ] ) unless $net;

    $c->stash->{network} = $net;

    $c->stash->{institute}  = $net->institute;
    $c->stash->{c_req_path} = $c->req->path;

    my @current_users = $c->model('DB::User')->search(
        {
            active                    => 1,
            city_id                   => undef,
            institute_id              => $c->stash->{institute}->id,
            'user_files.hide_listing' => [ 1, undef ]
        },
        { prefetch => 'user_files' }
    )->all;

    $c->detach( '/error_404', ['Nenhum admin de rede encontrado!'] ) unless @current_users;

    foreach my $current_user (@current_users) {
        my @files = $current_user->user_files;

        foreach my $file ( sort { $b->created_at->epoch <=> $a->created_at->epoch } @files ) {
            if ( $file->class_name eq 'custom.css' ) {
                $c->stash->{custom_css} = $file->public_url;
                last;
            }
        }
    }

    my @users = $c->stash->{network}->users->all;

    my @cities =
      $c->model('DB::City')
      ->search( { id => { 'in' => [ map { $_->city_id } @users ] } }, { order_by => [ 'pais', 'uf', 'name' ] } )
      ->as_hashref->all;

    $c->stash->{network_data} = {
        countries => [
            do {
                my %seen;
                grep { !$seen{$_}++ } grep { defined } map { $_->{country_id} } @cities;
              }
        ],
        users_ids => [
            do {
                my %seen;
                grep { !$seen{$_}++ } map { $_->id } @users;
              }
        ],
        cities => \@cities
    };

    my $cur_lang = exists $c->req->cookies->{cur_lang} ? $c->req->cookies->{cur_lang}->value : undef;

    if ( !defined $cur_lang ) {
        my $al = $c->req->headers->header('Accept-language');
        my $language = $self->lang_acceptor->accepts( $al, split /,/, $c->config->{available_langs} );

        $cur_lang = $language;
    }
    else {
        my %langs = map { $_ => 1 } split /,/, $c->config->{available_langs};
        $cur_lang = 'pt-br' unless exists $langs{$cur_lang};
    }

    $self->json_to_view(
        $c,
        institute_json => {
            (
                map { $_ => $c->stash->{institute}->$_ }
                  qw/
                  name
                  short_name
                  description
                  bypass_indicator_axis_if_custom
                  hide_empty_indicators
                  license
                  license_url
                  image_url
                  datapackage_autor
                  datapackage_autor_email
                  /
            )
        }
    );

    $c->set_lang($cur_lang);

    $c->response->cookies->{'cur_lang'} = {
        value   => $cur_lang,
        path    => '/',
        expires => '+3600h',
      }
      if !exists $c->req->cookies->{cur_lang} || $c->req->cookies->{cur_lang} ne $cur_lang;

}

sub featured_indicators_load : Private {
    my ( $self, $c ) = @_;

    my @countries = @{ $c->stash->{network_data}{countries} };
    my @users_ids = @{ $c->stash->{network_data}{users_ids} };

    my @indicators = $c->model('DB::Indicator')->search(
        {
            featured_in_home => 1,
            '-or'            => [
                { visibility_level => 'public' },
                { visibility_level => 'country', visibility_country_id => { 'in' => \@countries } },
                { visibility_level => 'private', visibility_user_id => { 'in' => \@users_ids } },
                { visibility_level => 'restrict', 'indicator_user_visibilities.user_id' => { 'in' => \@users_ids } },
            ]
        },
        { join => 'indicator_user_visibilities', order_by => 'me.name' }
    )->as_hashref->all;

    $c->stash( featured_indicators => \@indicators, );
}

sub mapa_site : Chained('institute_load') PathPart('mapa-do-site') Args(0) {
    my ( $self, $c ) = @_;

    my @countries = @{ $c->stash->{network_data}{countries} };
    my @users_ids = @{ $c->stash->{network_data}{users_ids} };

    my @indicators = $c->model('DB::Indicator')->search(
        {
            '-or' => [
                { visibility_level => 'public' },
                { visibility_level => 'country', visibility_country_id => { 'in' => \@countries } },
                { visibility_level => 'private', visibility_user_id => { 'in' => \@users_ids } },
                { visibility_level => 'restrict', 'indicator_user_visibilities.user_id' => { 'in' => \@users_ids } },
            ]
        },
        { join => 'indicator_user_visibilities', order_by => 'me.name' }
    )->as_hashref->all;

    $c->stash(
        cities     => $c->stash->{network_data}{cities},
        indicators => \@indicators,
        template   => 'mapa_site.tt'
    );
}

sub build_indicators_menu : Chained('institute_load') PathPart(':indicators') Args(0) {
    my ( $self, $c, $no_template ) = @_;

    my @countries = @{ $c->stash->{network_data}{countries} };
    my @users_ids = @{ $c->stash->{network_data}{users_ids} };

    my @indicators = $c->model('DB::Indicator')->search(
        {
            '-or' => [
                { visibility_level => 'public' },
                { visibility_level => 'country', visibility_country_id => { 'in' => \@countries } },
                { visibility_level => 'private', visibility_user_id => { 'in' => \@users_ids } },
                { visibility_level => 'restrict', 'indicator_user_visibilities.user_id' => { 'in' => \@users_ids } },
            ]
        },
        {
            join     => 'indicator_user_visibilities',
            prefetch => 'axis',
            order_by => 'me.name'
        }
    )->as_hashref->all;

    my $city = $c->stash->{city};

    my $user_id = $city && $c->stash->{user} ? $c->stash->{user}{id} : undef;

    my $id_vs_group_name = {};
    my $groups           = {};
    my $group_id         = 0;

    my @custom_axis =
      $user_id
      ? $c->model('DB::UserIndicatorAxis')->search(
        {
            user_id => $user_id
        },
        {
            prefetch => 'user_indicator_axis_items'
        }
      )->as_hashref->all
      : ();

    if (@custom_axis) {
        my $ind_vs_group = {};

        foreach my $g (@custom_axis) {

            foreach ( @{ $g->{user_indicator_axis_items} } ) {
                push @{ $ind_vs_group->{ $_->{indicator_id} } }, $g->{name};
            }
        }

        for my $i (@indicators) {
            next if !exists $ind_vs_group->{ $i->{id} };

            foreach my $group_name ( @{ $ind_vs_group->{ $i->{id} } } ) {
                if ( !exists $groups->{$group_name} ) {
                    $group_id++;

                    $groups->{$group_name}         = $group_id;
                    $id_vs_group_name->{$group_id} = $group_name;
                }

                push @{ $i->{groups} }, $groups->{$group_name};
            }
        }
    }

    my $region = $c->stash->{region} ? { $c->stash->{region}->get_inflated_columns } : $c->stash->{region};

    my $selected_indicator = $c->stash->{indicator};

    my $active_group = {
        name => 'Todos os indicadores',
        id   => 0
    };

    my $institute = $c->stash->{institute};

    my $count_used_groups = {};

    for my $i (@indicators) {

        if ( !exists $groups->{ $i->{axis}{name} } ) {
            $group_id++;

            $id_vs_group_name->{$group_id} = $i->{axis}{name};
            $groups->{ $i->{axis}{name} } = $group_id;
        }

        my $group_id = $groups->{ $i->{axis}{name} };

        # se ja tem algum grupo, entao nao verifica se precisa inserir
        if ( $i->{groups} && @{ $i->{groups} } > 0 ) {
            if ( !$institute->bypass_indicator_axis_if_custom ) {
                push @{ $i->{groups} }, $group_id;
                $count_used_groups->{$group_id}++;
            }
            else {
                $count_used_groups->{$group_id} = 0 if !exists $count_used_groups->{$group_id};
            }
        }
        else {
            push @{ $i->{groups} }, $group_id;

            $count_used_groups->{$group_id}++;
        }

        if ( $selected_indicator && $selected_indicator->{id} == $i->{id} ) {
            $i->{selected} = 1;

            $active_group = {
                name => $id_vs_group_name->{ $i->{groups}[0] },
                id   => $i->{groups}[0]
            };
        }

        if ($region) {

            $i->{href} = join '/', '', $city->{pais}, $city->{uf}, $city->{name_uri}, 'regiao', $region->{name_url},
              $i->{name_url};

        }
        elsif ($city) {

            $i->{href} = join '/', '', $city->{pais}, $city->{uf}, $city->{name_uri}, $i->{name_url};

        }
        else {
            $i->{href} = '/' . $i->{name_url};
        }
    }

    # todos os $count_used_groups = 0 sao eixos (nao grupos), que nao
    # foram usados em nenhum indicador.
    while ( my ( $group_id, $count ) = each %$count_used_groups ) {
        next unless $count == 0;

        delete $groups->{ $id_vs_group_name->{$group_id} };
        delete $id_vs_group_name->{$group_id};
    }

    if ( $active_group->{id} ) {
        for my $i (@indicators) {
            $i->{visible} = ( grep { /^$active_group->{id}$/ } @{ $i->{groups} } ) ? 1 : 0;
        }
    }

    $c->stash(
        groups       => $groups,
        active_group => $active_group,
        indicators   => \@indicators,

    );

    $c->stash( template => 'list_indicators.tt' ) if !$no_template;
}

sub download_redir : Chained('root') PathPart('download') Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect( '/dados-abertos', 301 );
}

sub download : Chained('institute_load') PathPart('dados-abertos') Args(0) {
    my ( $self, $c ) = @_;

    $self->mapa_site($c);

    $c->stash(
        template => 'download.tt',
        title    => 'Dados abertos'
    );
}

sub network_page : Chained('institute_load') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
}

sub network_pais : Chained('network_page') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $sigla ) = @_;
    $c->stash->{pais} = $sigla;
}

sub network_estado : Chained('network_pais') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $estado ) = @_;
    $c->stash->{estado} = $estado;
}

sub network_cidade : Chained('network_estado') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $cidade ) = @_;
    $c->stash->{cidade} = $cidade;

    $self->stash_tela_cidade($c);

    $c->stash->{title} = $c->stash->{city}{name} . ', ' . $c->stash->{city}{uf};

    $self->load_region_names($c);

    if ( $self->load_best_pratices( $c, only_count => 1 ) ) {
        $c->stash->{best_pratices_link} = $c->uri_for( $self->action_for('best_pratice_list'),
            [ $c->stash->{pais}, $c->stash->{estado}, $c->stash->{cidade} ] );
    }

    if (
        $c->model('DB::UserFile')->search(
            {
                user_id      => $c->stash->{user}{id},
                hide_listing => 0
            }
        )->count
      ) {
        $c->stash->{files_link} = $c->uri_for( $self->action_for('user_file_list'),
            [ $c->stash->{pais}, $c->stash->{estado}, $c->stash->{cidade} ] );
    }

}

sub load_region_names {
    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::UserRegion')->search(
        {
            user_id => $c->stash->{user}{id}
        }
    )->as_hashref;

    while ( my $row = $rs->next ) {
        $c->stash->{region_classification_name}{ $row->{depth_level} } = $row->{region_classification_name};
    }

    $c->stash->{region_classification_name}{2} ||= 'Região';
    $c->stash->{region_classification_name}{3} ||= 'Subregião';

}

sub cidade_regioes : Chained('network_cidade') PathPart('regiao') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{title}    = $c->stash->{city}{name} . ', ' . $c->stash->{city}{uf} . ' - ' . $c->loc('Regiões');
    $c->stash->{template} = 'home_cidade_region.tt';
}

sub cidade_indicadores : Chained('network_cidade') PathPart('indicadores') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{title}    = $c->stash->{city}{name} . ', ' . $c->stash->{city}{uf} . ' - ' . $c->loc('Indicadores');
    $c->stash->{template} = 'home_cidade_indicator.tt';
}

sub cidade_regiao : Chained('network_cidade') PathPart('regiao') CaptureArgs(1) {
    my ( $self, $c, $regiao ) = @_;
    $c->stash->{regiao_url} = $regiao;

    $self->stash_tela_regiao($c);

    $c->stash->{title} = $c->stash->{region}->name . ' - ' . $c->stash->{city}{name} . ', ' . $c->stash->{city}{uf};
}

sub cidade_regiao_indicator : Chained('cidade_regiao') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $indicator ) = @_;

    $c->stash->{indicator} = $indicator;
    $self->stash_tela_indicator($c);

    my $region = $c->stash->{region};

    $c->stash( template => 'home_region_indicator.tt' );

    $self->stash_distritos($c);

    $self->stash_comparacao_distritos($c);

    $c->forward( 'build_indicators_menu', [1] );
}

sub stash_distritos {
    my ( $self, $c ) = @_;

    my $schema    = $c->model('DB');
    my $region    = $c->stash->{region};
    my $indicator = $c->stash->{indicator};
    my $user      = $c->stash->{user};

    my @fatores = $schema->resultset('ViewFatorDesigualdade')->search(
        {},
        {
            bind         => [ $region->id, $indicator->{id}, $user->{id} ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->all;

    $c->stash->{fator_desigualdade} = \@fatores;

    if ( $c->stash->{current_part} && $c->stash->{current_part} eq 'fator_desigualdade' ) {
        $c->stash(
            template        => 'parts/fator_desigualdade.tt',
            without_wrapper => 1
        );
    }
}

sub stash_comparacao_distritos {
    my ( $self, $c ) = @_;

    my $schema    = $c->model('DB');
    my $region    = $c->stash->{region};
    my $indicator = $c->stash->{indicator};
    my $user      = $c->stash->{user};

    $c->stash->{color_index} = [ '#D7E7FF', '#A5DFF7', '#5A9CE8', '#0041B5', '#20007B', '#F1F174' ];

    my $poly_reg3 = {};
    foreach my $reg ( @{ $c->stash->{city}{regions} } ) {
        next unless $reg->{subregions};

        foreach my $sub ( @{ $reg->{subregions} } ) {
            next unless $sub->{polygon_path};

            push @{ $poly_reg3->{ $reg->{id} } }, $sub->{polygon_path};
        }

    }

    my $valor_rs = $schema->resultset('ViewValuesRegion')->search(
        {},
        {
            bind =>
              [ $region->depth_level, $region->id, $user->{id}, $indicator->{id}, $user->{id}, $indicator->{id}, ],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    );
    my $por_ano = {};

    while ( my $r = $valor_rs->next ) {
        $r->{variation_name} ||= '';

        $r->{polygon_path} = $r->{polygon_path} ? [ $r->{polygon_path} ] : $poly_reg3->{ $r->{id} };

        push @{ $por_ano->{ delete $r->{valid_from} }{ delete $r->{variation_name} } }, $r;
    }

    my $freq = Iota::Statistics::Frequency->new();

    my $out = {};
    while ( my ( $ano, $variacoes ) = each %$por_ano ) {
        while ( my ( $variacao, $distritos ) = each %$variacoes ) {

            my $stat = $freq->iterate($distritos);

            my $definidos = [ grep { defined $_->{num} } @$distritos ];

            # melhor = mais alto, entao inverte as cores
            if ( $indicator->{sort_direction} eq 'greater value' ) {
                $_->{i} = 4 - $_->{i} for @$definidos;
                $distritos =
                  [ ( reverse grep { defined $_->{num} } @$distritos ), grep { !defined $_->{num} } @$distritos ];
                $definidos = [ reverse @$definidos ];
            }

            if ($stat) {
                $out->{$ano}{$variacao} = {
                    all    => $distritos,
                    top3   => [ $definidos->[0], $definidos->[1], $definidos->[2], ],
                    lower3 => [ $definidos->[-3], $definidos->[-2], $definidos->[-1] ],
                    mean   => $stat->mean()
                };
            }
            elsif ( @$definidos == 4 ) {
                $definidos->[0]{i} = 0;    # Alta / Melhor
                $definidos->[1]{i} = 1;    # acima media
                $definidos->[2]{i} = 3;    # abaixo da media
                $definidos->[3]{i} = 4;    # Baixa / Pior
            }
            elsif ( @$definidos == 3 ) {
                $definidos->[0]{i} = 0;    # Alta / Melhor
                $definidos->[1]{i} = 2;    # média
                $definidos->[2]{i} = 4;    # Baixa / Pior
            }
            elsif ( @$definidos == 2 ) {
                $definidos->[0]{i} = 0;    # Alta / Melhor
                $definidos->[1]{i} = 4;    # Baixa / Pior
            }
            else {
                $_->{i} = 5 for @$definidos;
            }

            $out->{$ano}{$variacao} = { all => $distritos }
              unless exists $out->{$ano}{$variacao};

            my @nao_definidos = grep { !defined $_->{num} } @$distritos;
            for (@nao_definidos) {
                $_->{i}   = 5;             # amarelo/sem valor
                $_->{num} = 'n/d';
            }
            push @$definidos, @nao_definidos;
        }
    }

    $c->stash->{analise_comparativa} = $out;

    if ( $c->stash->{current_part} && $c->stash->{current_part} eq 'analise_comparativa' ) {
        $c->stash(
            template        => 'parts/analise_comparativa.tt',
            without_wrapper => 1
        );
    }
}

sub cidade_regiao_indicator_render : Chained('cidade_regiao_indicator') PathPart('') Args(0) {
}

sub cidade_regiao_render : Chained('cidade_regiao') PathPart('') Args(0) {
}

sub network_render : Chained('network_cidade') PathPart('') Args(0) {
}

sub user_page : Chained('network_cidade') PathPart('pagina') CaptureArgs(2) {
    my ( $self, $c, $page_id, $title ) = @_;

    my $page = $c->model('DB::UserPage')->search(
        {
            id      => $page_id,
            user_id => $c->stash->{user}{id}
        }
    )->as_hashref->next;

    $c->detach('/error_404') unless $page;
    $c->stash->{page} = $page;

    $c->stash(
        template => 'home_cidade_pagina.tt',
        title    => $page->{title}
    );

}

sub user_page_render : Chained('user_page') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
}

sub best_pratice : Chained('network_cidade') PathPart('boa-pratica') CaptureArgs(2) {
    my ( $self, $c, $page_id, $title ) = @_;

    $self->load_best_pratices($c);

    my $page = $c->model('DB::UserBestPratice')->search(
        {
            'me.id'      => $page_id,
            'me.user_id' => $c->stash->{user}{id}
        },
        { prefetch => [ 'axis', { user_best_pratice_axes => 'axis' } ] }
    )->as_hashref->next;

    $c->detach('/error_404') unless $page;
    $c->stash->{best_pratice} = $page;

    $c->stash(
        template => 'home_cidade_boas_praticas.tt',
        title    => $page->{name}
    );

}

sub load_best_pratices {
    my ( $self, $c, %flags ) = @_;

    my $rs =
      $c->model('DB::UserBestPratice')->search( { user_id => $c->stash->{user}{id} }, { prefetch => 'axis' } )
      ->as_hashref;

    return $rs->count if exists $flags{only_count};

    my $out;
    while ( my $obj = $rs->next ) {
        push @{ $out->{ $obj->{axis}{name} } }, $obj;

        $obj->{link} = $c->uri_for( $self->action_for('best_pratice_render'),
            [ $c->stash->{pais}, $c->stash->{estado}, $c->stash->{cidade}, $obj->{id}, $obj->{name_url}, ] );
    }
    $c->stash->{best_pratices} = $out;
}

sub best_pratice_list : Chained('network_cidade') PathPart('boas-praticas') Args(0) {
    my ( $self, $c ) = @_;
    $self->load_best_pratices($c);
    $c->stash(
        template => 'home_cidade_boas_praticas_list.tt',
        title    => 'Boas Praticas de ' . $c->stash->{city}{name} . '/' . $c->stash->{estado}
    );
}

sub load_files {
    my ( $self, $c ) = @_;

    my $rs = $c->model('DB::UserFile')->search(
        {
            user_id      => $c->stash->{user}{id},
            hide_listing => 0
        },
        {
            order_by => [ 'class_name', 'public_name' ]
        }
    );

    my $out;
    while ( my $obj = $rs->next ) {
        push @{ $out->{ $obj->{class_name} } }, $obj;
    }
    $c->stash->{files} = $out;
}

sub user_file_list : Chained('network_cidade') PathPart('arquivos') Args(0) {
    my ( $self, $c ) = @_;
    $self->load_files($c);
    $c->stash(
        template => 'home_cidade_file_list.tt',
        title    => 'Lista de arquivos de ' . $c->stash->{city}{name} . '/' . $c->stash->{estado}
    );
}

sub best_pratice_render : Chained('best_pratice') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
}

sub network_indicator : Chained('network_cidade') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $indicator ) = @_;
    $c->stash->{indicator} = $indicator;
    $self->stash_tela_indicator($c);

    $c->forward( 'build_indicators_menu', [1] );
}

sub network_indicator_render : Chained('network_indicator') PathPart('') Args(0) {
    my ( $self, $c, $cidade ) = @_;
    $c->stash( template => 'home_indicador.tt' );
}

sub home_network_indicator : Chained('institute_load') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $nome ) = @_;

    $self->stash_indicator( $c, $nome );

    $self->stash_comparacao_cidades($c);

    $c->stash->{indicator} = { $c->stash->{indicator}->get_inflated_columns };

    $c->stash->{indicator}{created_at} = $c->stash->{indicator}{created_at}->datetime;

    $self->json_to_view( $c, indicator_json => $c->stash->{indicator} );

    if ( $c->stash->{current_part} && $c->stash->{current_part} =~ /^(comparacao_indicador_por_cidade)$/ ) {
        $c->stash(
            template        => "parts/$1.tt",
            without_wrapper => 1
        );
    }

    $c->forward( 'build_indicators_menu', [1] );
}

sub home_network_indicator_render : Chained('home_network_indicator') PathPart('') Args(0) {
}

sub stash_indicator {
    my ( $self, $c, $nome ) = @_;

    my $indicator = $c->model('DB::Indicator')->search( { name_url => $nome } )->next;

    $c->detach('/error_404') unless $indicator;
    $c->stash->{indicator} = $indicator;

    $c->stash(
        template => 'home_comparacao_indicador.tt',
        title    => 'Dados do indicador ' . $indicator->name
    );
}

sub stash_comparacao_cidades {
    my ( $self, $c ) = @_;

    $self->_add_default_periods($c);

    my $controller = $c->controller('API::Indicator::Chart');
    $controller->typify( $c, 'period_axis' );

    $c->stash->{user_id} = $c->stash->{network_data}{users_ids};

    $controller->render_GET($c);

    my $users = $c->stash->{rest}{users};
    foreach my $user_id ( keys %$users ) {

        $users->{$user_id}{user_id} = $user_id;
        if ( !exists $users->{$user_id}{city} ) {
            delete $users->{$user_id};
            next;
        }

        next unless ( exists $users->{$user_id}{data}{series} );

        my $series = $users->{$user_id}{data}{series};
        foreach my $serie (@$series) {
            $users->{$user_id}{by_period}{ $serie->{begin} } = $serie;
        }
    }

    $users = [ map { $users->{$_} } sort { $users->{$a}{city}{name} cmp $users->{$b}{city}{name} } keys %$users ];
    $c->stash->{users_series} = $users;

    if ( $c->stash->{indicator}->indicator_type eq 'varied' ) {
        my %all_variations;
        foreach my $user (@$users) {
            next unless exists $user->{by_period};

            # a ordem e nome das variacoes de qualquer "series" são sempre
            # as mesmas.
            $user->{variations} = [ map { $_->{name} } @{ $user->{data}{series}[0]{variations} } ];

            # agora precisa correr todas as variacoes e colocar chave=>valor
            # pra ficar mais simples de acessar pela view.
            foreach my $cur_serie ( @{ $user->{data}{series} } ) {
                do {
                    $all_variations{ $_->{name} } = 1;
                    $cur_serie->{by_variation}{ $_->{name} } = $_;
                  }
                  for ( @{ $cur_serie->{variations} } );
            }
        }

        $c->stash->{all_variations} = [ sort keys %all_variations ];
    }

    my $dados_mapa = {};

    foreach my $user (@$users) {
        next unless exists $user->{by_period};

        foreach my $valid ( keys %{ $user->{by_period} } ) {
            push @{ $dados_mapa->{$valid} },
              {
                val => $user->{by_period}{$valid}{avg},
                lat => $user->{city}{latitude},
                lng => $user->{city}{longitude},
              };
        }
    }

    $self->json_to_view( $c, dados_mapa_json => $dados_mapa );

    my $dados_grafico = { dados => [] };
    foreach my $period ( @{ $c->stash->{choosen_periods}[2] } ) {
        push @{ $dados_grafico->{labels} },
          Iota::IndicatorChart::PeriodAxis::get_label_of_period( $period, $c->stash->{indicator}->period );
    }

    my %shown = exists $c->req->params->{graphs} ? map { $_ => 1 } split '-', $c->req->params->{graphs} : ();

    foreach my $user ( @{ $c->stash->{users_series} } ) {
        next unless exists $user->{by_period};

        my $user_id = $user->{user_id};

        my $reg_user = {
            show => exists $shown{$user_id} ? 1 : 0,
            id   => $user_id,
            nome => $user->{city}{name},
            valores => []
        };

        my $idx = 0;
        foreach my $period ( @{ $c->stash->{choosen_periods}[2] } ) {

            if ( exists $user->{by_period}{$period} ) {
                $reg_user->{valores}[$idx] = $user->{by_period}{$period}{avg};
            }
            $idx++;
        }
        push @{ $dados_grafico->{dados} }, $reg_user;
    }

    $self->json_to_view( $c, dados_grafico_json => $dados_grafico );

    $c->stash->{current_tab} =
      exists $c->req->params->{view}
      ? $c->req->params->{view}
      : 'table';
}

sub json_to_view {
    my ( $self, $c, $st, $obj ) = @_;

    $c->stash->{$st} = JSON::XS->new->utf8(0)->encode($obj);
}

sub _add_default_periods {
    my ( $self, $c ) = @_;

    my $data_atual   = DateTime->now;
    my $ano_anterior = $data_atual->year() - 1;

    my $grupos      = 4;
    my $step        = 4;
    my $ano_inicial = $ano_anterior - ( $grupos * $step ) + 1;

    my @periods;

    my $cont = 0;
    my $ant;
    my @loop;
    for my $i ( $ano_inicial .. $ano_anterior ) {
        push @loop, "$i-01-01";
        if ( $cont == 0 ) {
            $ant = "$i-01-01";
        }
        elsif ( $cont == $step - 1 ) {
            push @periods, [ $ant, "$i-01-01", [@loop], $c->req->uri_with( { valid_from => $ant } )->as_string ];
            undef @loop;
            $cont = -1;
        }

        $cont++;
    }
    $c->stash->{data_periods} = \@periods;

    $c->req->params->{valid_from} =
      exists $c->req->params->{valid_from}
      ? $c->req->params->{valid_from}
      : $periods[-1][0];

    my $ativo = undef;

    my $i = 0;
  PROCURA: foreach my $grupo (@periods) {

        foreach my $periodo ( @{ $grupo->[2] } ) {
            if ( $periodo eq $c->req->params->{valid_from} ) {
                $ativo = $i;
                last PROCURA;
            }
        }
        $i++;
    }

    if ( defined $ativo ) {
        $c->req->params->{from}      = $periods[$ativo][0];
        $c->req->params->{to}        = $periods[$ativo][1];
        $c->stash->{choosen_periods} = $periods[$ativo];
    }
    else {
        $c->req->params->{from}      = $periods[-1][0];
        $c->req->params->{to}        = $periods[-1][1];
        $c->stash->{choosen_periods} = $periods[-1];
    }

}

sub stash_tela_indicator {
    my ( $self, $c ) = @_;

    # carrega a cidade/user
    $self->stash_tela_cidade($c);

    # anti bug de quem chamar isso sem ler o fonte ^^
    delete $c->stash->{template};

    my @countries = @{ $c->stash->{network_data}{countries} };
    my @users_ids = @{ $c->stash->{network_data}{users_ids} };

    my $indicator = $c->model('DB::Indicator')->search(
        {
            name_url => $c->stash->{indicator},
            '-or'    => [
                { visibility_level => 'public' },
                { visibility_level => 'country', visibility_country_id => { 'in' => \@countries } },
                { visibility_level => 'private', visibility_user_id => { 'in' => \@users_ids } },
                { visibility_level => 'restrict', 'indicator_user_visibilities.user_id' => { 'in' => \@users_ids } },
            ]
        },
        { join => 'indicator_user_visibilities' }
    )->as_hashref->next;
    $c->detach( '/error_404', ['Indicador não encontrado!'] ) unless $indicator;

    $c->stash->{indicator} = $indicator;

    $c->stash->{title} = $indicator->{name} . ' de ' . $c->stash->{city}{name} . ', ' . $c->stash->{city}{uf};
}

sub stash_tela_cidade {
    my ( $self, $c ) = @_;

    my $city = $c->model('DB::City')->search(
        {
            pais     => lc $c->stash->{pais},
            uf       => uc $c->stash->{estado},
            name_uri => lc $c->stash->{cidade}
        },
        { prefetch => 'regions' }
    )->as_hashref->next;

    $c->detach('/error_404') unless $city;

    $self->_setup_regions_level( $c, $city ) if ( $city->{regions} && @{ $city->{regions} } > 0 );

    my $user = $c->model('DB::User')->search(
        {
            city_id                    => $city->{id},
            'me.active'                => 1,
            'network_users.network_id' => $c->stash->{network}->id
        },
        { join => 'network_users' }
    )->next;

    $c->detach('/error_404') unless $user;

    $c->stash->{user_obj} = $user;
    my $public = $c->controller('API::UserPublic')->user_public_load($c);
    $c->stash( public => $public );

    my @files = $user->user_files;

    foreach my $file ( sort { $b->created_at->epoch <=> $a->created_at->epoch } @files ) {
        if ( $file->class_name eq 'custom.css' ) {

            #$c->assets->include( $file->public_url, 9999 );
            $c->stash->{custom_css} = $file->public_url;
            last;
        }
    }

    my $menurs = $user->user_menus->search(
        undef,
        {
            order_by => [ { '-asc' => 'me.position' }, 'me.id' ],
            prefetch => 'page'
        }
    );
    $self->_load_menu( $c, $menurs );

    $self->_load_variables( $c, $user );

    $user = { $user->get_inflated_columns };
    $c->stash(
        city     => $city,
        user     => $user,
        template => 'home_cidade.tt',
    );
}

sub _setup_regions_level {
    my ( $self, $c, $city ) = @_;

    my $out = {};
    foreach my $reg ( @{ $city->{regions} } ) {
        my $x = $reg->{upper_region} || $reg->{id};
        push @{ $out->{$x} }, $reg;
    }

    my @regions;
    foreach my $id ( keys %$out ) {
        my $pai;
        my @subs;
        foreach my $r ( @{ $out->{$id} } ) {
            $r->{url} = $c->uri_for( $self->action_for('cidade_regiao_render'),
                [ $city->{pais}, $city->{uf}, $city->{name_uri}, $r->{name_url} ] )->as_string;

            if ( !$r->{upper_region} ) {
                $pai = $r;
            }
            else {
                push @subs, $r;
            }
        }
        $pai->{subregions} = \@subs;
        push @regions, $pai;
    }

    $city->{regions} = \@regions;
}

sub _load_variables {
    my ( $self, $c, $user ) = @_;

    my @admins_ids = map { $_->id } $c->stash->{network}->users->search(
        {
            city_id => undef    # admins
        }
    )->all;
    my $mid = $user->id;

    my $var_confrs = $c->model('DB::UserVariableConfig')->search( { user_id => [ @admins_ids, $mid ] } );

    my $aux = {};
    while ( my $conf = $var_confrs->next ) {
        push @{ $aux->{ $conf->variable_id } }, [ $conf->display_in_home, $conf->user_id, $conf->position ];
    }

    my $show  = {};
    my $order = {};

    # a configuracao do usuario sempre tem preferencia sob a do admin
    while ( my ( $vid, $wants ) = each %$aux ) {

        if ( @$wants == 1 && $wants->[0][0] ) {
            $order->{$vid} = $wants->[0][2];
            $show->{$vid}++ and last;
        }

        foreach my $conf (@$wants) {
            if ( $conf->[1] == $mid && $conf->[0] ) {

                $order->{$vid} = $conf->[2];
                $show->{$vid}++ and last;
            }
        }

    }

    my $values = $user->variable_values->search(
        { variable_id => { 'in' => [ keys %$show ] }, },
        {
            order_by => [            { -desc => 'valid_from' } ],
            prefetch => { 'variable' => 'measurement_unit' }
        }
    );

    my %exists;
    my @variables;
    while ( my $val = $values->next ) {
        next if $exists{ $val->variable_id }++;

        push @variables, $val;
    }

    @variables = sort { $order->{ $a->variable_id } <=> $order->{ $b->variable_id } } @variables;

    $c->stash( user_basic_variables => \@variables );
}

sub _load_menu {
    my ( $self, $c, $menurs ) = @_;

    my $menu = {};
    my @menu_out;

    while ( my $m = $menurs->next ) {
        my $pai = $m->menu_id || $m->id;
        push( @{ $menu->{$pai} }, $m );
    }

    while ( my ( $id, $rows ) = each %$menu ) {
        my $menu;
        for my $menurs (@$rows) {
            if ( !$menurs->menu_id ) {
                $menu = {
                    title => $menurs->title,
                    (
                        link => $menurs->page_id
                        ? $c->uri_for(
                            $self->action_for('user_page_render'),
                            [
                                $c->stash->{pais}, $c->stash->{estado}, $c->stash->{cidade},
                                $menurs->page_id,  $menurs->page->title_url,
                            ]
                          )
                        : ''
                    )
                };
                push @menu_out, $menu;
            }
        }

        for my $menurs (@$rows) {
            if ( $menurs->menu_id ) {
                push @{ $menu->{subs} },
                  {
                    title => $menurs->title,
                    (
                        link => $menurs->page_id
                        ? $c->uri_for(
                            $self->action_for('user_page_render'),
                            [
                                $c->stash->{pais}, $c->stash->{estado}, $c->stash->{cidade},
                                $menurs->page_id,  $menurs->page->title_url,
                            ]
                          )
                        : ''
                    )
                  };
            }
        }
    }

    $c->stash( menu => \@menu_out, );

}

sub stash_tela_regiao {
    my ( $self, $c ) = @_;

    my $region = $c->model('DB::Region')->search(
        {
            name_url => lc $c->stash->{regiao_url},
            city_id  => $c->stash->{city}{id}
        }
    )->next;

    $c->detach('/error_404') unless $region;
    $c->stash(
        region   => $region,
        template => 'home_region.tt',
    );

    if ( $region->depth_level == 2 ) {
        my @subregions = $c->model('DB::Region')->search(
            {
                city_id      => $c->stash->{city}{id},
                upper_region => $region->id
            }
        )->all;
        $c->stash->{subregions} = \@subregions;
    }

    $self->_load_region_variables($c);
}

sub _load_region_variables {
    my ( $self, $c ) = @_;

    my $region = $c->stash->{region};
    my @admins_ids = map { $_->id } $c->stash->{network}->users->search(
        {
            city_id => undef    # admins
        }
    )->all;
    my $mid = $c->stash->{user}{id};
    my $var_confrs = $region->user_variable_region_configs->search( { user_id => [ @admins_ids, $mid ] } );

    my $aux = {};
    while ( my $conf = $var_confrs->next ) {
        push @{ $aux->{ $conf->variable_id } }, [ $conf->display_in_home, $conf->user_id, $conf->position ];
    }

    my $show  = {};
    my $order = {};

    # a configuracao do usuario sempre tem preferencia sob a do admin
    while ( my ( $vid, $wants ) = each %$aux ) {

        if ( @$wants == 1 && $wants->[0][0] ) {
            $order->{$vid} = $wants->[0][2];
            $show->{$vid}++ and last;
        }

        foreach my $conf (@$wants) {
            if ( $conf->[1] == $mid && $conf->[0] ) {

                $order->{$vid} = $conf->[2];
                $show->{$vid}++ and last;
            }
        }

    }
    my $active_value = exists $c->req->params->{active_value} ? $c->req->params->{active_value} : 1;
    my $values = $region->region_variable_values->search(
        {
            'me.variable_id'  => { 'in' => [ keys %$show ] },
            'me.user_id'      => $mid,
            'me.active_value' => $active_value
        },
        {
            order_by => [            { -desc => 'me.valid_from' } ],
            prefetch => { 'variable' => 'measurement_unit' }
        }
    );

    my %exists;
    my @variables;
    while ( my $val = $values->next ) {
        next if $exists{ $val->variable_id }++;

        push @variables, $val;
    }

    @variables = sort { $order->{ $a->variable_id } <=> $order->{ $b->variable_id } } @variables;

    $c->stash( basic_variables => \@variables );

}

__PACKAGE__->meta->make_immutable;

1;
