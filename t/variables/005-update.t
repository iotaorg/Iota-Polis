
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
                    api_key                       => 'test',
                    'variable.create.name'        => 'Foo Bar',
                    'variable.create.cognomen'    => 'foobar',
                    'variable.create.explanation' => 'a foo with bar',
                    'variable.create.type'        => 'str',
                    'variable.create.period'      => 'yearly',
                    'variable.create.source'      => 'God',
                ]
            );
            ok( $res->is_success, 'variable created!' );
            is( $res->code, 201, 'created!' );

            use URI;
            my $uri = URI->new( $res->header('Location') );
            $uri->query_form( api_key => 'test' );

            # update var
            ( $res, $c ) = ctx_request(
                POST $uri->path_query,
                [
                    'variable.update.name'   => 'BarFoo',
                    'variable.update.type'   => 'int',
                    'variable.update.period' => 'weekly',
                    'variable.update.source' => 'Lulu',
                ]
            );
            ok( $res->is_success, 'var updated' );
            is( $res->code, 202, 'var updated -- 202 Accepted' );

            use JSON qw(from_json);
            my $variable = eval { from_json( $res->content ) };

            ok( my $updated_var = $schema->resultset('Variable')->find( { id => $variable->{id} } ), 'var in DB' );

            is( $updated_var->type,   'int',    'updated ok' );
            is( $updated_var->name,   'BarFoo', 'name ok' );
            is( $updated_var->source, 'Lulu',   'source ok' );

            die 'rollback';
        }
    );

};

die $@ unless $@ =~ /rollback/;

done_testing;
