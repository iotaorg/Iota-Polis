
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
my $city_uri;
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

            $city_uri = $res->header('Location');
            ( $res, $c ) = ctx_request(
                POST $city_uri . '/region',
                [
                    api_key                                     => 'test',
                    'city.region.create.name'                   => 'a region',
                    'city.region.create.subregions_valid_after' => '2020-01-01',
                    'city.region.create.description'            => 'with no description',
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

            note 'update valid_time para uma data futura';
            eval {
                $schema->txn_do(
                    sub {
                        my $ii;
                        &update_region_valid_time( $reg1, undef );
                        &add_value( $reg1_uri, '100', '2002' );
                        &add_value( $reg1_uri, '130', '2003' );
                        &add_value( $reg1_uri, '150', '2004' );

                        &update_region_valid_time_api( $reg1, '2005-01-01' );
                        &add_value( $reg2_uri, '80', '2005' );
                        &add_value( $reg3_uri, '82', '2005' );

                        &add_value( $reg2_uri, '95', '2006' );
                        &add_value( $reg3_uri, '94', '2006' );

                        &add_value( $reg1_uri, '166', '2008' );    # tem q sobreviver e ativo!
                        &add_value( $reg2_uri, '95',  '2008' );
                        &add_value( $reg3_uri, '94',  '2008' );

                        &add_value( $reg2_uri, '40', '2010' );
                        &add_value( $reg3_uri, '50', '2010' );

                        &add_value( $reg2_uri, '11', '2011' );
                        &add_value( $reg3_uri, '12', '2011' );

                        my $ret = &get_values($reg1);
                        is( @$ret, 8, '8 records' );
                        for my $i ( 0 .. 2 ) {
                            is( $ret->[$i]{generated_by_compute}, 0, ( 2002 + $i ) . ' is not computed' );
                            is( $ret->[$i]{active_value},         1, ( 2002 + $i ) . ' active' );
                            is( $ret->[$i]{valid_from}, ( 2002 + $i ) . '-01-01', 'is expected date' );
                        }

                        for my $i ( 3 .. 7 ) {
                            is( $ret->[$i]{generated_by_compute}, 1, ( 2002 + $i ) . ' is computed' );
                            is( $ret->[$i]{active_value},         1, ( 2002 + $i ) . ' active' );
                        }
                        is( $ret->[6]{valid_from}, '2010-01-01', 'is expected date' );
                        is( $ret->[7]{valid_from}, '2011-01-01', 'is expected date' );

                        $ret = &get_values( $reg1, 1 );
                        is( @$ret,                           1,            'only 1 not active' );
                        is( $ret->[0]{valid_from},           '2008-01-01', 'and it is 2008-01-01' );
                        is( $ret->[0]{generated_by_compute}, 0,            'have generated_by_compute=0' );

                        # para todos levels = 3, apagar 2005 até 2009 inclusive
                        # para todos levels = 2, update active_value=true where generated_by_compute=false
                        &update_region_valid_time_api( $reg1, '2010-01-01' );
                        $ret = &get_values($reg1);
                        is( @$ret, 6, '6 records' );
                        for my $i ( 0 .. 2 ) {
                            is( $ret->[$i]{generated_by_compute}, 0, ( 2002 + $i ) . ' is not computed' );
                            is( $ret->[$i]{active_value},         1, ( 2002 + $i ) . ' active' );
                            is( $ret->[$i]{valid_from}, ( 2002 + $i ) . '-01-01', 'is expected date' );
                        }
                        is( $ret->[3]{generated_by_compute}, 0,            '2008 is not computed' );
                        is( $ret->[3]{active_value},         1,            '2008 active' );
                        is( $ret->[3]{valid_from},           '2008-01-01', 'is expected date' );

                        for my $i ( 4 .. 5 ) {
                            is( $ret->[$i]{generated_by_compute}, 1, ( 2007 + $i ) . ' is computed' );
                            is( $ret->[$i]{active_value},         1, ( 2007 + $i ) . ' active' );
                        }

                        $ret = &get_values( $reg1, 1 );
                        is( @$ret, 0, '0 records' );

                        die 'undo-savepoint';
                    }
                );
                die $@ unless $@ =~ /undo-savepoint/;
            };

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;

sub update_region_valid_time {

    $schema->resultset('Region')->find(
        {
            id => shift->{id}
        }
      )->update(
        {
            subregions_valid_after => shift
        }
      );

}

sub update_region_valid_time_api {
    my ( $reg, $valid ) = @_;
    my ( $res, $c )     = ctx_request(
        POST $city_uri . '/region/' . $reg->{id},
        [
            api_key                                     => 'test',
            'city.region.update.subregions_valid_after' => $valid,
        ]
    );

    ok( $res->is_success, 'region updated!' );
}

sub add_value {
    my ( $region, $value, $year, $expcode ) = @_;

    $value =~ s/,/./;
    $expcode ||= 201;

    note "POSTING $region/value\tyear $year, value $value";

    # PUT normal
    my $req = POST $region . '/value',
      [
        'region.variable.value.put.value'         => $value,
        'region.variable.value.put.variable_id'   => $variable->{id},
        'region.variable.value.put.value_of_date' => $year . '-01-01'
      ];
    $req->method('PUT');
    my ( $res, $c ) = ctx_request($req);

    ok( $res->is_success, 'variable value created' ) if $expcode == 201;
    is( $res->code, $expcode, 'response code is ' . $expcode );
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
