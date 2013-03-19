use utf8;
package Iota::Schema::Result::Institute;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Institute

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");

=head1 TABLE: C<institute>

=cut

__PACKAGE__->table("institute");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'institute_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 short_name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 users_can_edit_value

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 users_can_edit_groups

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 can_use_custom_css

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 can_use_custom_pages

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "institute_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "short_name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "users_can_edit_value",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "users_can_edit_groups",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "can_use_custom_css",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "can_use_custom_pages",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<institute_short_name_key>

=over 4

=item * L</short_name>

=back

=cut

__PACKAGE__->add_unique_constraint("institute_short_name_key", ["short_name"]);

=head1 RELATIONS

=head2 networks

Type: has_many

Related object: L<Iota::Schema::Result::Network>

=cut

__PACKAGE__->has_many(
  "networks",
  "Iota::Schema::Result::Network",
  { "foreign.institute_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-03-19 15:15:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zvmyewE6RdQSTmqGRbzLWw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
