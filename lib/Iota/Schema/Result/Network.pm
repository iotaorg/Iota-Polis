use utf8;
package Iota::Schema::Result::Network;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Network

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

=head1 TABLE: C<network>

=cut

__PACKAGE__->table("network");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'network_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 name_url

  data_type: 'text'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 created_by

  data_type: 'integer'
  is_nullable: 0

=head2 institute_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 domain_name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 ga_account

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 is_virtual

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 rdf_identifier

  data_type: 'boolean'
  is_nullable: 1

=head2 topic

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 template_name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 axis_name

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 description

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 text_content

  data_type: 'json'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "network_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "name_url",
  { data_type => "text", is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "created_by",
  { data_type => "integer", is_nullable => 0 },
  "institute_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "domain_name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "ga_account",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "is_virtual",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "rdf_identifier",
  { data_type => "boolean", is_nullable => 1 },
  "topic",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "template_name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "axis_name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "description",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "text_content",
  { data_type => "json", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<network_domain_name_key>

=over 4

=item * L</domain_name>

=back

=cut

__PACKAGE__->add_unique_constraint("network_domain_name_key", ["domain_name"]);

=head2 C<network_name_url_key>

=over 4

=item * L</name_url>

=back

=cut

__PACKAGE__->add_unique_constraint("network_name_url_key", ["name_url"]);

=head2 C<network_rdf_identifier_key>

=over 4

=item * L</rdf_identifier>

=back

=cut

__PACKAGE__->add_unique_constraint("network_rdf_identifier_key", ["rdf_identifier"]);

=head1 RELATIONS

=head2 end_user_indicators

Type: has_many

Related object: L<Iota::Schema::Result::EndUserIndicator>

=cut

__PACKAGE__->has_many(
  "end_user_indicators",
  "Iota::Schema::Result::EndUserIndicator",
  { "foreign.network_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_network_configs

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorNetworkConfig>

=cut

__PACKAGE__->has_many(
  "indicator_network_configs",
  "Iota::Schema::Result::IndicatorNetworkConfig",
  { "foreign.network_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_network_visibilities

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorNetworkVisibility>

=cut

__PACKAGE__->has_many(
  "indicator_network_visibilities",
  "Iota::Schema::Result::IndicatorNetworkVisibility",
  { "foreign.network_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 institute

Type: belongs_to

Related object: L<Iota::Schema::Result::Institute>

=cut

__PACKAGE__->belongs_to(
  "institute",
  "Iota::Schema::Result::Institute",
  { id => "institute_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 network_users

Type: has_many

Related object: L<Iota::Schema::Result::NetworkUser>

=cut

__PACKAGE__->has_many(
  "network_users",
  "Iota::Schema::Result::NetworkUser",
  { "foreign.network_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: many_to_many

Composing rels: L</network_users> -> user

=cut

__PACKAGE__->many_to_many("users", "network_users", "user");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-05-27 18:34:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H3rc3d+TtjKfWuntGxAE6A

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
