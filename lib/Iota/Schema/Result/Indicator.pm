use utf8;
package Iota::Schema::Result::Indicator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::Indicator

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

=head1 TABLE: C<indicator>

=cut

__PACKAGE__->table("indicator");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'indicator_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 formula

  data_type: 'text'
  is_nullable: 0

=head2 goal

  data_type: 'numeric'
  is_nullable: 1

=head2 goal_explanation

  data_type: 'text'
  is_nullable: 1

=head2 goal_source

  data_type: 'text'
  is_nullable: 1

=head2 goal_operator

  data_type: 'text'
  is_nullable: 1

=head2 axis_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 source

  data_type: 'text'
  is_nullable: 1

=head2 explanation

  data_type: 'text'
  is_nullable: 1

=head2 tags

  data_type: 'text'
  is_nullable: 1

=head2 chart_name

  data_type: 'text'
  is_nullable: 1

=head2 sort_direction

  data_type: 'enum'
  extra: {custom_type_name => "sort_direction_enum",list => ["greater value","greater rating","lowest value","lowest rating"]}
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 name_url

  data_type: 'text'
  is_nullable: 1

=head2 observations

  data_type: 'text'
  is_nullable: 1

=head2 variety_name

  data_type: 'text'
  is_nullable: 1

=head2 indicator_type

  data_type: 'text'
  default_value: 'normal'
  is_nullable: 0

=head2 all_variations_variables_are_required

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 summarization_method

  data_type: 'text'
  default_value: 'sum'
  is_nullable: 0

=head2 indicator_admins

  data_type: 'text'
  is_nullable: 1

=head2 dynamic_variations

  data_type: 'boolean'
  is_nullable: 1

=head2 visibility_user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 visibility_country_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 formula_human

  data_type: 'text'
  is_nullable: 1

=head2 period

  data_type: 'text'
  is_nullable: 1

=head2 variable_type

  data_type: 'text'
  is_nullable: 1

=head2 featured_in_home

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 visibility_level

  data_type: 'enum'
  default_value: 'public'
  extra: {custom_type_name => "tp_visibility_level",list => ["public","private","restrict","network","session"]}
  is_nullable: 0

=head2 is_fake

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 append_on_result

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 prepend_on_result

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 graph_type

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=head2 display_order

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "indicator_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "formula",
  { data_type => "text", is_nullable => 0 },
  "goal",
  { data_type => "numeric", is_nullable => 1 },
  "goal_explanation",
  { data_type => "text", is_nullable => 1 },
  "goal_source",
  { data_type => "text", is_nullable => 1 },
  "goal_operator",
  { data_type => "text", is_nullable => 1 },
  "axis_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "source",
  { data_type => "text", is_nullable => 1 },
  "explanation",
  { data_type => "text", is_nullable => 1 },
  "tags",
  { data_type => "text", is_nullable => 1 },
  "chart_name",
  { data_type => "text", is_nullable => 1 },
  "sort_direction",
  {
    data_type => "enum",
    extra => {
      custom_type_name => "sort_direction_enum",
      list => [
        "greater value",
        "greater rating",
        "lowest value",
        "lowest rating",
      ],
    },
    is_nullable => 1,
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "name_url",
  { data_type => "text", is_nullable => 1 },
  "observations",
  { data_type => "text", is_nullable => 1 },
  "variety_name",
  { data_type => "text", is_nullable => 1 },
  "indicator_type",
  { data_type => "text", default_value => "normal", is_nullable => 0 },
  "all_variations_variables_are_required",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "summarization_method",
  { data_type => "text", default_value => "sum", is_nullable => 0 },
  "indicator_admins",
  { data_type => "text", is_nullable => 1 },
  "dynamic_variations",
  { data_type => "boolean", is_nullable => 1 },
  "visibility_user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "visibility_country_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "formula_human",
  { data_type => "text", is_nullable => 1 },
  "period",
  { data_type => "text", is_nullable => 1 },
  "variable_type",
  { data_type => "text", is_nullable => 1 },
  "featured_in_home",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "visibility_level",
  {
    data_type => "enum",
    default_value => "public",
    extra => {
      custom_type_name => "tp_visibility_level",
      list => ["public", "private", "restrict", "network", "session"],
    },
    is_nullable => 0,
  },
  "is_fake",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "append_on_result",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "prepend_on_result",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "graph_type",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "display_order",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<indicator_cognomen_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("indicator_cognomen_key", ["name"]);

=head2 C<indicator_name_url_key2>

=over 4

=item * L</name_url>

=back

=cut

__PACKAGE__->add_unique_constraint("indicator_name_url_key2", ["name_url"]);

=head1 RELATIONS

=head2 axis

Type: belongs_to

Related object: L<Iota::Schema::Result::Axis>

=cut

__PACKAGE__->belongs_to(
  "axis",
  "Iota::Schema::Result::Axis",
  { id => "axis_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 end_user_indicator_users

Type: has_many

Related object: L<Iota::Schema::Result::EndUserIndicatorUser>

=cut

__PACKAGE__->has_many(
  "end_user_indicator_users",
  "Iota::Schema::Result::EndUserIndicatorUser",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 end_user_indicators

Type: has_many

Related object: L<Iota::Schema::Result::EndUserIndicator>

=cut

__PACKAGE__->has_many(
  "end_user_indicators",
  "Iota::Schema::Result::EndUserIndicator",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_network_configs

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorNetworkConfig>

=cut

__PACKAGE__->has_many(
  "indicator_network_configs",
  "Iota::Schema::Result::IndicatorNetworkConfig",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_network_visibilities

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorNetworkVisibility>

=cut

__PACKAGE__->has_many(
  "indicator_network_visibilities",
  "Iota::Schema::Result::IndicatorNetworkVisibility",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_user_visibilities

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorUserVisibility>

=cut

__PACKAGE__->has_many(
  "indicator_user_visibilities",
  "Iota::Schema::Result::IndicatorUserVisibility",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_values

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorValue>

=cut

__PACKAGE__->has_many(
  "indicator_values",
  "Iota::Schema::Result::IndicatorValue",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_variables

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorVariable>

=cut

__PACKAGE__->has_many(
  "indicator_variables",
  "Iota::Schema::Result::IndicatorVariable",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_variables_variations

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorVariablesVariation>

=cut

__PACKAGE__->has_many(
  "indicator_variables_variations",
  "Iota::Schema::Result::IndicatorVariablesVariation",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 indicator_variations

Type: has_many

Related object: L<Iota::Schema::Result::IndicatorVariation>

=cut

__PACKAGE__->has_many(
  "indicator_variations",
  "Iota::Schema::Result::IndicatorVariation",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Iota::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 user_indicator_configs

Type: has_many

Related object: L<Iota::Schema::Result::UserIndicatorConfig>

=cut

__PACKAGE__->has_many(
  "user_indicator_configs",
  "Iota::Schema::Result::UserIndicatorConfig",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_indicators

Type: has_many

Related object: L<Iota::Schema::Result::UserIndicator>

=cut

__PACKAGE__->has_many(
  "user_indicators",
  "Iota::Schema::Result::UserIndicator",
  { "foreign.indicator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 visibility_country

Type: belongs_to

Related object: L<Iota::Schema::Result::Country>

=cut

__PACKAGE__->belongs_to(
  "visibility_country",
  "Iota::Schema::Result::Country",
  { id => "visibility_country_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 visibility_user

Type: belongs_to

Related object: L<Iota::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "visibility_user",
  "Iota::Schema::Result::User",
  { id => "visibility_user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-07-25 15:24:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mdCaVQ42MfV8/0P2kvao7g

__PACKAGE__->belongs_to(
    "owner",
    "Iota::Schema::Result::User",
    { "foreign.id"  => "self.user_id" },
    { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

sub populate_rdf {
    my ( $object, %opts ) = @_;

    my $schema                   = $object->result_source->schema;
    my $rdf                      = $opts{rdf};
    my $valid_values_for_lex_key = $opts{valid_values_for_lex_key};

    my $uri = 'http://' . $opts{rdf_domain} . '/rdf/indicator/' . $object->id;

    $rdf->assert_literal( $uri, 'rdf:ID', 'indicator' );

    # id => dct:Identifier
    $rdf->assert_literal( $uri, 'dct:Identifier', $object->id );

    # period => dct:accrualPeriodicity
    $rdf->assert_resource( $uri, 'dct:accrualPeriodicity',
        $schema->period_to_rdf( $object->period ) );

    # reserva memoria uma vez só
    my %str = ();

    # name => dct:title
    %str = $valid_values_for_lex_key->( $object->name );

    $rdf->assert_literal( $uri, 'dct:title', $rdf->new_literal( $str{$_}, $_ ) )
      for keys %str;

    # explanation => dct:description
    %str = $valid_values_for_lex_key->( $object->explanation );

    $rdf->assert_literal( $uri, 'dct:description',
        $rdf->new_literal( $str{$_}, $_ ) )
      for keys %str;

    # name_url => dct:subject
    $rdf->assert_literal( $uri, 'dct:subject', $object->name_url );

    return 1;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
