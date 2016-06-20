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


sub light_institute_load : Chained('root') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # se veio ?part, guarda na stash e remove ele da req para nao atrapalhar novas geracoes de URLs
    $c->stash->{current_part} = delete $c->req->params->{part};
    if ( $c->stash->{current_part} ) {
        delete $c->req->{query_parameters}{part};
        $c->req->uri( $c->req->uri_with( { part => undef } ) );
    }

    my $domain = $c->req->uri->host;
    my $net    = $c->model('DB::Network')->search(
        { domain_name => $domain },
        {
            join     => 'institute',
            collapse => 1,
            columns  => [
                qw/
                  me.id
                  me.name
                  me.name_url
                  me.ga_account
                  me.domain_name
                  me.topic

                  institute.id
                  institute.name
                  institute.short_name
                  institute.bypass_indicator_axis_if_custom
                  institute.hide_empty_indicators
                  /
            ]
        }
    )->first;

    # gambiarra pra ter rede nos testes..
    if ( exists $ENV{HARNESS_ACTIVE} && $ENV{HARNESS_ACTIVE} ) {
        $net = $c->model('DB::Network')->search(
            {
                institute_id => exists $ENV{HARNESS_ACTIVE_institute_id}
                ? $ENV{HARNESS_ACTIVE_institute_id}
                : 1
            }
        )->first;
    }

    $c->detach( '/error_404', [ $c->loc('Nenhuma rede para o dominio') . ' ' . $domain . '!' ] )
      unless $net;

    $c->stash->{network} = $net;

    $c->stash->{institute}  = $net->institute;
    $c->stash->{c_req_path} = $c->req->path;
}

sub load_status_msgs : Private {
    my ( $self, $c ) = @_;

    $c->load_status_msgs;
    my $status_msg = $c->stash->{status_msg};
    my $error_msg  = $c->stash->{error_msg};

    @{ $c->stash }{ keys %$status_msg } = values %$status_msg
      if ref $status_msg eq 'HASH';
    @{ $c->stash }{ keys %$error_msg } = values %$error_msg
      if ref $error_msg eq 'HASH';

    if ( $c->stash->{form_error} && ref $c->stash->{form_error} eq 'HASH' ) {
        my $aff = {};
        foreach ( keys %{ $c->stash->{form_error} } ) {
            my ( $hm, $fo ) = $_ =~ /(.+)\.(.+)$/;

            $aff->{$hm} = $fo;
        }
        $c->stash->{form_error} = $aff;
    }
}

use Storable qw/nfreeze thaw/;
use Redis;
my $redis = Redis->new;

sub institute_load : Chained('light_institute_load') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{institute_loaded} = 1;

    # garante que foi executado sempre o light quando o foi executado apenas o 'institute_load'
    # nos lugares que chama essa sub sem ser via $c->forward ou semelhantes
    $c->forward('light_institute_load') if !exists $c->stash->{c_req_path};

=pod
    my @inner_page;

    if (exists $c->stash->{user_obj} && ref $c->stash->{user_obj}  eq 'Iota::Model::DB::User'){
        @inner_page = (
            '-or' => [
                { 'user.city_id' => undef },
                { 'user.id' => $c->stash->{user_obj}->id }
            ]
        );
    }
=cut

    my $without_topic = $c->req->params->{without_topic} ? '1' : '0';
    my $cache_key = $c->stash->{network}->users->search(
        { active => 1, },
        {
            select => [
                \'md5( array_agg(me.user_id::text || me.network_id::text || coalesce("user".city_id::text, \'\')  ORDER BY me.user_id, me.network_id, "user".city_id )::text)'
            ],
            as           => ['md5'],
            result_class => 'DBIx::Class::ResultClass::HashRefInflator'
        }
    )->next;

    $cache_key = $cache_key->{md5};
    $cache_key = "institute_load-$cache_key-$without_topic";

    my $schema = $c->model('DB')->schema;
    my $stash  = $redis->get($cache_key);

    if ($stash) {
        $stash = thaw($stash);
        $_->result_source->schema($schema) for @{ $stash->{current_all_users} };
        $_->result_source->schema($schema) for @{ $stash->{current_admins} };
    }
    else {

        my @users = $c->stash->{network}->users->search(
            {
                active => 1,
                ( $without_topic ? ( 'network.topic' => 0 ) : () )
            },
            {
                prefetch => [ 'city', 'network_users' ],
                join => { network_users => 'network' }
            }
        )->all;

        $stash->{current_all_users} = \@users;

        my @cities =
          sort { $a->pais . $a->uf . $a->name cmp $b->pais . $b->uf . $b->name }
          map  { $_->city }
          grep { defined $_->city_id } @users;

        $stash->{network_data} = {
            states => [
                do {
                    my %seen;
                    grep { !$seen{$_}++ }
                      grep { defined } map { $_->state_id } @cities;
                  }
            ],
            users_ids => [
                do {
                    my %seen;
                    grep { !$seen{$_}++ }
                      map { $_->id } grep { defined $_->city_id } @users;
                  }
            ],

            # redes de todos os usuarios que estão na pagina.
            network_ids => [
                do {
                    my %seen;
                    grep { !$seen{$_}++ } map {
                        map { $_->network_id }
                          $_->network_users
                    } grep { defined $_->city_id } @users;
                  }
            ],

            # rede selecionada do idioma.
            network_id => [ $c->stash->{network}->id ],
            admins_ids => [ map { $_->id } grep { !defined $_->city_id } @users ],
            cities     => \@cities
        };

        $stash->{current_admins} = [ grep { !$_->city_id } @users ];

        $redis->setex( $cache_key, 60 * 5, nfreeze($stash) );
    }

    my @current_admins = @{ $stash->{current_admins} };
    $c->detach( '/error_404', ['Nenhum admin de rede encontrado!'] )
      unless @current_admins;
    $c->detach( '/error_404', ['Mais de um admin de rede para o dominio encontrado!'] )
      if @current_admins > 1;

    delete $stash->{current_admins};
    $c->stash->{$_} = $stash->{$_} for keys %$stash;

    # tem que ver pra nao ler do mesmo lugar?
    $c->stash->{current_cities} = $c->stash->{network_data}{cities};

    my $admin = $c->stash->{current_admin_user} = $current_admins[0];

    my @files = $admin->user_files->search( undef, { columns => [qw/created_at class_name private_path/] } )->all;

    foreach my $file ( sort { $b->created_at->epoch <=> $a->created_at->epoch } @files ) {
        if ( $file->class_name eq 'custom.css' ) {
            my $path      = $file->private_path;
            my $path_root = $c->path_to('root');
            $path =~ s/$path_root//;

            # coloca por ultimo na ordem dos arquivos
            $c->assets->include( $path, 99999 );

            # sai do loop pra nao pegar todas as versoes do arquivo
            last;
        }
    }

    # utilizada para fazer filtro dos indicados
    # apenas para a cidade dele [o segundo parametro é ignorado]
    $c->stash->{current_city_user_id} = undef;

    my $cur_lang =
      exists $c->req->cookies->{cur_lang}
      ? $c->req->cookies->{cur_lang}->value
      : undef;

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
                  bypass_indicator_axis_if_custom
                  hide_empty_indicators
                  /
            )
        }
    );

    $c->set_lang($cur_lang);

=pod
    so precisa setar a lingua quando entra no endpoint, se nao, usa a padrao mesmo..
    $c->response->cookies->{'cur_lang'} = {
        value   => $cur_lang,
        path    => '/',
        expires => '+3600h',
      }
      if !exists $c->req->cookies->{cur_lang}
      || $c->req->cookies->{cur_lang} ne $cur_lang;
=cut

}


__PACKAGE__->meta->make_immutable;

1;
