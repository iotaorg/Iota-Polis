
use strict;
use warnings;

use Test::More;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Catalyst::Test q(Iota);

use HTTP::Request::Common;
use Package::Stash;

use Iota::TestOnly::Mock::AuthUser;

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
            my ( $res, $c );
            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                => 'test',
                    'variable.create.name' => 'FooBar',
                ]
            );
            ok( !$res->is_success, 'invalid request' );
            is( $res->code, 400, 'invalid request' );

            ( $res, $c ) = ctx_request(
                POST '/api/variable',
                [
                    api_key                               => 'test',
                    'variable.create.name'                => 'Foo Bar',
                    'variable.create.cognomen'            => 'foobar',
                    'variable.create.explanation'         => 'a foo with bar',
                    'variable.create.type'                => 'int',
                    'variable.create.period'              => 'yearly',
                    'variable.create.source'              => 'God',
                    'variable.create.measurement_unit_id' => '1',
                    'variable.create.colors' => '{"foo":"#FFWWDD"}',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );
            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            ( $res, $c ) = ctx_request( GET $uri->path_query );
            ok( $res->is_success, 'varible exists' );
            is( $res->code, 200, 'varible exists -- 200 Success' );
            ok $res->content =~ /#FFWWDD/;

            ( $res, $c ) = ctx_request( GET '/api/variable?api_key=test' );

            ok( $res->is_success, 'listing ok!' );
            is( $res->code, 200, 'list 200' );


            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
