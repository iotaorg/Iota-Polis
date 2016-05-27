package CatalystX::Plugin::Lexicon;

use Moose;
with 'MooseX::Emulate::Class::Accessor::Fast';
use MRO::Compat;
use Catalyst::Exception ();
use Data::Dumper;

use overload ();
use Carp;

use namespace::clean -except => 'meta';

our $VERSION = '0.35';
$VERSION = eval $VERSION;


sub setup {
    my $c = shift;

    $c->maybe::next::method(@_);

    return $c;
}

sub initialize_after_setup {
}

sub setup_lexicon_plugin {
}


sub lexicon_reload_all {

}

sub lexicon_reload_self {

}

sub valid_values_for_lex_key {

}

sub loc {
    my ( undef, $text ) = @_;
    $text;
}

sub set_lang {
}

sub get_lang {

}

__PACKAGE__;

__END__

# use $c->logx('your message', ? {indicator_id => 123}) anywhere you want.

