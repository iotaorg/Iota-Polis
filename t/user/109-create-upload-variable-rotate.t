
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Temp qw/ tempfile /;
use Text::CSV_XS;
use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;
use Path::Class qw(dir);
use Iota::TestOnly::Mock::AuthUser;
use JSON;

my $schema = Iota->model('DB');
my $stash  = Package::Stash->new('Catalyst::Plugin::Authentication');
my $user   = Iota::TestOnly::Mock::AuthUser->new;

$Iota::TestOnly::Mock::AuthUser::_id    = 1;
@Iota::TestOnly::Mock::AuthUser::_roles = qw/ admin /;

$stash->add_symbol( '&user',  sub { return $user } );
$stash->add_symbol( '&_user', sub { return $user } );

eval {
    $schema->txn_do(
        sub {
            my $city = $schema->resultset('City')->create(
                {
                    uf   => 'SP',
                    name => 'Pederneiras'
                },
            );

            my ( $res, $c ) = ctx_request(
                POST '/api/city/' . $city->id . '/region',
                [
                    api_key                          => 'test',
                    'city.region.create.name'        => 'a region',
                    'city.region.create.description' => 'with no description',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg1 = eval { from_json( $res->content ) };
            ok( $reg1->{id}, 'has id' );

            ( $res, $c ) = ctx_request(
                POST '/api/city/' . $city->id . '/region',
                [
                    api_key                          => 'test',
                    'city.region.create.name'        => 'a region 2',
                    'city.region.create.description' => 'with no description',
                ]
            );

            ok( $res->is_success, 'region created!' );
            is( $res->code, 201, 'region created!' );

            my $reg2 = eval { from_json( $res->content ) };
            ok( $reg2->{id}, 'has id' );

            $schema->resultset('Region')->find( $reg1->{id} )->update( { id => '3555406' } );
            $schema->resultset('Region')->find( $reg2->{id} )->update( { id => '3510500' } );

            ( $res, $c ) = ctx_request(
                POST '/api/user',
                [
                    api_key                                 => 'test',
                    'user.create.name'                      => 'Foo Bar',
                    'user.create.email'                     => 'foo@email.com',
                    'user.create.password'                  => 'foobarquux1',
                    'user.create.nome_responsavel_cadastro' => 'nome_responsavel_cadastro',
                    'user.create.password_confirm'          => 'foobarquux1',
                    'user.create.city_id'                   => $city->id,
                    'user.create.role'                      => 'admin',
                    'user.create.network_id'                => '1',
                    'user.create.city_summary'              => 'testeteste'
                ]
            );
            ok( $res->is_success, 'user created' );
            is( $res->code, 201, 'user created' );

            ( $res, $c ) = ctx_request(
                POST '/api/variable/value_via_file_rotate',
                'Content-Type' => 'form-data',
                Content        => [
                    api_key   => 'test',
                    'arquivo' => ["$Bin/upload-rotate.xls"],
                ]
            );
            ok( $res->is_success, 'OK' );
            is( $res->code, 200, 'upload done!' );

            use DDP; p $res;

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
