
package Iota::Controller::API::Variable::ValueViaFileRotate;

use Moose;
use JSON;
use Text2URI;
use String::Random;
use Path::Class qw(dir);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config( default => 'application/json' );

sub base : Chained('/api/variable/base') : PathPart('value_via_file_rotate') : CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash->{collection} = $c->model('DB::VariableValue');

}

sub file : Chained('base') : PathPart('') : Args(0) ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub file_POST {
    my ( $self, $c ) = @_;

    $self->status_forbidden( $c, message => "access denied", ), $c->detach
      unless $c->check_any_user_role(qw(admin superadmin user));
    my $upload = $c->req->upload('arquivo');
    eval {
        if ($upload) {
            my $user_id = $c->user->id;

            $c->logx( 'Enviou arquivo ' . $upload->basename );
            my $foo      = String::Random->new;
            my $t        = Text2URI->new();
            my $filename = sprintf(
                'user_%i_%s_%s_%s',
                $user_id, 'upload-file',
                $foo->randpattern('sssss'),
                substr( $t->translate( $upload->basename ), 0, 200 ),
            );
            my $private_path =
              $c->config->{private_path} =~ /^\//o
              ? dir( $c->config->{private_path} )->resolve . '/' . $filename
              : Iota->path_to( $c->config->{private_path}, $filename );

            unless ( $upload->copy_to($private_path) ) {
                $c->res->body( to_json( { error => "Copy failed: $!" } ) );
                $c->detach;
            }
            chmod 0644, $private_path;

            my $public_path = $c->uri_for( $c->config->{public_url} . '/' . $filename )->as_string;
            my $file = $c->model('FileRotate')->process(
                user_id      => $user_id,
                upload       => $upload,
                schema       => $c->model('DB'),
                app          => $c,
                private_path => $private_path,
                public_path => $public_path,
            );

            $c->res->body( to_json($file) );

        }
        else {
            die "no upload found\n";
        }
    };
    print STDERR " >>>>> $@" if $@;
    $c->res->body( to_json( { error => "$@" } ) ) if $@;

    $c->detach;

}

1;
