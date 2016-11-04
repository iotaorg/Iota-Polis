
use strict;
use warnings;
use URI;
use Test::More;
use JSON qw(from_json);

use FindBin qw($Bin);
use lib "$Bin/../../lib";

use Catalyst::Test q(Iota);

my $variable;
my $indicator;
use HTTP::Request::Common qw(GET POST DELETE PUT);
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 2;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my ( $res, $c );

            my $inst = $schema->resultset('Institute')->create(
                {
                    active_me_when_empty        => 1,
                    user_overwrite_computerized => 1,
                    name                        => 'name',
                    short_name                  => 'short_name',

                }
            );
            my $net = $schema->resultset('Network')->create(
                {
                    name         => 'name',
                    name_url     => 'short_name',
                    domain_name  => 'domain_name',
                    created_by   => 1,
                    institute_id => $inst->id,
                }
            );

            my $u = $schema->resultset('User')->create(
                {
                    name            => 'name',
                    email           => 'email@email.com',
                    institute_id    => $inst->id,
                    password        => '!!!',
                    regions_enabled => 1
                }
            );
            $u->add_to_user_roles( { role => { name => 'admin' } } );
            $u->add_to_network_users( { network_id => $net->id } );

            $ENV{HARNESS_ACTIVE_institute_id} = $inst->id;

            $Iota::TestOnly::Mock::AuthUser::_id = $u->id;

            ( $res, $c ) = ctx_request(
                POST '/api/city',
                [
                    api_key            => 'test',
                    'city.create.name' => 'FooBar',

                ]
            );
            ok( !$res->is_success, 'invalid request' );
            is( $res->code, 400, 'invalid request' );

            ( $res, $c ) = ctx_request(
                POST '/api/city',
                [
                    api_key                 => 'test',
                    'city.create.name'      => 'Foo Bar',
                    'city.create.state_id'  => 1,
                    'city.create.latitude'  => 5666.55,
                    'city.create.longitude' => 1000.11,
                ]
            );
            ok( $res->is_success, 'city created!' );
            is( $res->code, 201, 'created!' );

            my $city_uri = $res->header('Location');
            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                                     => 'test',
                    'city.region.create.name'                   => 'a region',
                    'city.region.create.description'            => 'with no description',
                    'city.region.create.subregions_valid_after' => '2010-01-01',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg1_uri = $res->header('Location');
            my $reg1 = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                           => 'test',
                    'city.region.create.name'         => 'second region',
                    'city.region.create.upper_region' => $reg1->{id},
                    'city.region.create.description'  => 'with Description',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg2_uri = $res->header('Location');
            ( $res, $c ) = ctx_request( GET $reg2_uri );
            my $reg2 = eval { from_json( $res->content ) };
            ( $reg2->{id} ) = $reg2_uri =~ /\/([0-9]+)$/;

            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                           => 'test',
                    'city.region.create.name'         => 'second region x',
                    'city.region.create.upper_region' => $reg1->{id},
                    'city.region.create.description'  => 'with Descriptionx',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg3_uri = $res->header('Location');
            ( $res, $c ) = ctx_request( GET $reg3_uri );
            my $reg3 = eval { from_json( $res->content ) };
            ( $reg3->{id} ) = $reg3_uri =~ /\/([0-9]+)$/;

            ( $res, $c ) = ctx_request( GET $reg1_uri );
            my $obj = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                       => 'test',
                    'variable.create.name'        => 'Foo Bar',
                    'variable.create.cognomen'    => 'foobar',
                    'variable.create.period'      => 'yearly',
                    'variable.create.explanation' => 'a foo with bar',
                    'variable.create.type'        => 'num',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            $variable = eval { from_json( $res->content ) };

            ( $res, $c ) = ctx_request(
                POST '/api/indicator',
                [
                    api_key                          => 'test',
                    'indicator.create.name'          => 'Foo Bar',
                    'indicator.create.formula'       => '1 + $' . $variable->{id},
                    'indicator.create.axis_id'       => '1',
                    'indicator.create.explanation'   => 'explanation',
                    'indicator.create.source'        => 'me',
                    'indicator.create.goal_source'   => '@fulano',
                    'indicator.create.chart_name'    => 'pie',
                    'indicator.create.goal_operator' => '>=',
                    'indicator.create.tags'          => 'you,me,she',

                    'indicator.create.observations'     => 'lala',
                    'indicator.create.visibility_level' => 'public',
                ]
            );

            $indicator = eval { from_json( $res->content ) };

            &update_region_valid_time( $reg1, '2010-01-01' );

            &add_value( $reg2_uri, '100', '2010' );
            my $tmp = &get_values($reg2);

            is( scalar @$tmp, '1', 'só tem 1 linha' );
            my $ii = &get_indicator( $reg2, '2010' );
            is_deeply( $ii, [101], 'valores salvos ok' );

            is( scalar @$tmp, '1', 'tem 1 linhas' );

            $tmp = &get_values($reg1);
            is( scalar @$tmp, '1', 'tem 1 linhas tambem na regiao 1' );

            $tmp = [ sort { $a->{valid_from} cmp $b->{valid_from} } @{$tmp} ];
            is( $tmp->[0]{value}, '100' );


            $tmp = &get_indicator( $reg1, '2010' );

            is( $tmp->[0], 101, '1 + 100' );

            # adiciona valor forcado na regiao de cima
            &add_value( $reg1_uri, '325', '2010' );
            $tmp = &get_indicator( $reg1, '2010' );

            is( $tmp->[0], 326, '1 + 325' );


            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;

sub update_region_valid_time {

    $schema->resultset('Region')->find( { id => shift->{id} } )->update( { subregions_valid_after => shift } );

}

sub add_value {
    my ( $region, $value, $year ) = @_;

    $value =~ s/,/./;

    # PUT normal
    my $req = POST $region . '/value',
      [
        'region.variable.value.put.value'         => $value,
        'region.variable.value.put.variable_id'   => $variable->{id},
        'region.variable.value.put.value_of_date' => $year . '-01-01'
      ];
    $req->method('PUT');
    my ( $res, $c ) = ctx_request($req);

    #use DDP;
    #p $res;
    #exit;
    ok( $res->is_success, 'variable value created' );
    is( $res->code, 201, 'value added -- 201 ' );
    my $id = eval { from_json( $res->content ) };

    return $id;
}

sub get_values {
    my ( $region, $not ) = @_;

    $not = $not ? 0 : 1;
    my ( $res, $c ) =
      ctx_request( GET '/api/user/'
          . $Iota::TestOnly::Mock::AuthUser::_id
          . '/variable?region_id='
          . $region->{id}
          . '&is_basic=0&variable_id='
          . $variable->{id}
          . '&active_value='
          . $not );

    is( $res->code, 200, 'list the values exists -- 200 Success' );
    my $list = eval { from_json( $res->content ) };
    return $list->{variables}[0]{values};
}

sub get_indicator {
    my ( $region, $year, ) = @_;

    my $list = [
        map { $_->{value} } $schema->resultset('IndicatorValue')->search(
            {

                valid_from => ( $year . '-01-01' ),
                ( $region ? ( region_id => $region->{id} ) : () )
            },
            { result_class => 'DBIx::Class::ResultClass::HashRefInflator', columns => ['value'] }
        )->all
    ];

    return $list;
}

# see end() in php
sub get_the_key {
    my ($hash) = @_;
    my ($k)    = keys %$hash;
    return $hash->{$k};
}
