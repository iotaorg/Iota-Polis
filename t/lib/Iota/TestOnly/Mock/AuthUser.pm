
package Iota::TestOnly::Mock::AuthUser;
use strict;
use warnings;
use base qw/Catalyst::Authentication::User/;
use List::MoreUtils qw(any);

our $_id;
our $_network_id;
our @_roles;
our $cur_lang = 'pt-br';

sub roles { return @_roles; }

sub id {
    return $_id;
}

sub cur_lang {
    return $cur_lang;
}

sub network_id {
    return $_network_id || 1;
}

sub supports {
    shift;
    return 0 if any { $_ =~ /self_check/ } @_;
    return 1;
}

use List::MoreUtils qw(any all);

sub self_check { 1 }

sub self_check_any { 1 }

sub check_any_role {
    my ( $self, @roles ) = @_;
    return any {
        my $role = $_;
        any { $_ eq $role } @roles;
    }
    $self->roles;
}

sub check_roles {
    my ( $self, @roles ) = @_;
    return all {
        my $role = $_;
        any { $_ eq $role } @roles;
    }
    $self->roles;
}

1;
