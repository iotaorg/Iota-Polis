package RNSP::IndicatorFormula;

use Moose;
use Math::Expression::Evaluator;


has formula => (
    is         => 'rw',
    isa        => 'Str',
    required   => 1
);

has auto_parse => (
    is         => 'ro',
    isa        => 'Bool',
    default    => sub { 1 }
);

has auto_check => (
    is         => 'ro',
    isa        => 'Bool',
    default    => sub { 1 }
);

has schema => (
    is         => 'ro',
    isa        => 'Any',
    required   => 1
);


has _math_ee => (
    is      => 'rw',
    isa     => 'Math::Expression::Evaluator',
    lazy    => 1,
    default => sub { Math::Expression::Evaluator->new }
);

has _compiled => (
    is      => 'rw',
    isa     => 'Any',
);


has _variable => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    lazy    => 1,
    default => sub { [] },
    traits  => [qw(Array)],
    handles => {
        variables         => 'elements',
        _add_variable     => 'push',
        _variable_count   => 'count',
        _get_varaible     => 'get',
        _clear_variables  => 'clear',
    }
);

has _is_string => (
    is => 'rw',
    isa => 'Bool',
    default => sub { 0 }
);

sub BUILD {
    my ($self) = @_;
    if ($self->auto_parse){ $self->parse }
}

sub parse {
    my ($self) = @_;
    my $formula = $self->formula;

    $self->_clear_variables;
    # caputar todas as variaveis
    $self->_add_variable($1) while ($formula =~ /\$(\d+)\b/go);

    # troca por V<ID>
    $formula =~ s/\$(\d+)\b/V$1/go;

    if ($formula =~ /concatenar/io){
        $self->_is_string(1);
    }else{
        my $ee = $self->_math_ee;
        $self->_compiled($ee->parse($formula)->compiled);
    }

    $self->check() if $self->auto_check;
}

sub evaluate {
    my ($self, %vars) = @_;

    foreach($self->variables){
        return '-' unless defined $vars{$_};
    }

    return $self->_is_string ? $self->as_string(%vars) : $self->_compiled()->( { ( map { "V" . $_ => $vars{$_} } $self->variables ) } );
}

sub as_string {
    my ($self, %vars) = @_;
    my $str = '';
    foreach ($self->variables){

        $str .= $vars{$_} . ' ';
    }
    chop($str);
    return $str;
}

sub check {
    my ($self) = @_;

    my @variables = $self->schema->resultset('Variable')->search({id => [$self->variables]} )->all;

    $self->_check_period(\@variables);

    $self->_check_only_numbers(\@variables) unless $self->_is_string;

}

sub _check_period {
    my ($self, $arr) = @_;

    my $periods = {};
    $periods->{$_->period()}++ foreach (@$arr);

    die 'variables with mixed period not allowed! IDs: ' .
        join (keys %$periods) if keys %$periods > 1;
}

sub _check_only_numbers {
    my ($self, $arr) = @_;
    foreach (@$arr){
        die "variable ".$_->id ." is a ".$_->type." and it's not allowed! " if $_->type ne 'int' && $_->type ne 'num';
    }
}

1;
