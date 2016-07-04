
package Iota::Schema::ResultSet::Variable;

use namespace::autoclean;

use Moose;
extends 'DBIx::Class::ResultSet';
with 'Iota::Role::Verification';
with 'Iota::Schema::Role::InflateAsHashRef';

use Data::Verifier;
use JSON qw /encode_json/;
use String::Random;
use MooseX::Types::Email qw/EmailAddress/;

use Iota::Types qw /VariableType/;

sub _build_verifier_scope_name { 'variable' }

sub verifiers_specs {
    my $self = shift;
    return {
        create => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                colors      => { required => 0, type => 'Str' },
                name        => { required => 1, type => 'Str' },
                explanation => { required => 1, type => 'Str' },
                cognomen    => {
                    required   => 1,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;
                        return 0
                          if $self->result_source->schema->resultset('Variable')
                          ->search( { cognomen => $r->get_value('cognomen') } )->count;

                        return $r->get_value('cognomen') =~ /^(?:[A-Z0-9_])+$/i;
                      }
                },
                type                => { required => 1, type => VariableType },
                user_id             => { required => 1, type => 'Int' },
                source              => { required => 0, type => 'Str' },
                user_type           => { required => 0, type => 'Str' },
                period              => { required => 0, type => 'Str' },
                measurement_unit_id => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return
                          defined $self->result_source->schema->resultset('MeasurementUnit')
                          ->find( { id => $r->get_value('measurement_unit_id') } );
                      }
                },
                is_basic             => { required => 0, type => 'Bool' },
                summarization_method => { required => 0, type => 'Str' },
            },
        ),

        update => Data::Verifier->new(
            filters => [qw(trim)],
            profile => {
                colors      => { required => 0, type => 'Str' },
                id          => { required => 1, type => 'Int' },
                name        => { required => 0, type => 'Str' },
                explanation => { required => 0, type => 'Str' },
                cognomen    => {
                    required   => 0,
                    type       => 'Str',
                    post_check => sub {
                        my $r = shift;
                        return 0
                          if $self->result_source->schema->resultset('Variable')
                          ->search( { id => { '!=' => $r->get_value('id') }, cognomen => $r->get_value('cognomen') } )
                          ->count;

                        return $r->get_value('cognomen') =~ /^(?:[A-Z0-9_])+$/i;
                      }
                },
                type                => { required => 0, type => VariableType },
                source              => { required => 0, type => 'Str' },
                period              => { required => 1, type => 'Str' },
                measurement_unit_id => {
                    required   => 0,
                    type       => 'Int',
                    post_check => sub {
                        my $r = shift;
                        return
                          defined $self->result_source->schema->resultset('MeasurementUnit')
                          ->find( { id => $r->get_value('measurement_unit_id') } );
                      }
                },
                is_basic             => { required => 0, type => 'Bool' },
                summarization_method => { required => 0, type => 'Str' },

            },
        ),

    };
}

sub action_specs {
    my $self = shift;
    return {
        create => sub {
            my %values = shift->valid_values;
            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            my $var = $self->create( \%values );

            $var->discard_changes;
            return $var;
        },
        update => sub {
            my %values = shift->valid_values;

            do { delete $values{$_} unless defined $values{$_} }
              for keys %values;
            return unless keys %values;

            # TODO atualizar o nomes la no indicador, se mudou.

            my $var = $self->find( delete $values{id} );

            if ( exists $values{summarization_method} && $var->summarization_method ne $values{summarization_method} ) {
                $self->result_source->schema->f_compute_all_upper_regions();
            }

            $var->update( \%values );
            $var->discard_changes;
            return $var;
        },

    };
}

1;

