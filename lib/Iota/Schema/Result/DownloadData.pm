use utf8;
package Iota::Schema::Result::DownloadData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::DownloadData

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
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<download_data>

=cut

__PACKAGE__->table("download_data");

=head1 ACCESSORS

=head2 city_id

  data_type: 'integer'
  is_nullable: 1

=head2 city_name

  data_type: 'text'
  is_nullable: 1

=head2 axis_name

  data_type: 'text'
  is_nullable: 1

=head2 indicator_id

  data_type: 'integer'
  is_nullable: 1

=head2 indicator_name

  data_type: 'text'
  is_nullable: 1

=head2 formula_human

  data_type: 'text'
  is_nullable: 1

=head2 formula_explanation

  data_type: 'text'
  is_nullable: 1

=head2 formula

  data_type: 'text'
  is_nullable: 1

=head2 nossa_leitura

  data_type: 'text'
  is_nullable: 1

=head2 period

  data_type: 'text'
  is_nullable: 1

=head2 valid_from

  data_type: 'date'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 user_goal

  data_type: 'text'
  is_nullable: 1

=head2 institute_id

  data_type: 'integer'
  is_nullable: 1

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 region_id

  data_type: 'integer'
  is_nullable: 1

=head2 sources

  data_type: 'character varying[]'
  is_nullable: 1

=head2 region_name

  data_type: 'text'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 values_used

  data_type: 'text'
  is_nullable: 1
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "city_id",
  { data_type => "integer", is_nullable => 1 },
  "city_name",
  { data_type => "text", is_nullable => 1 },
  "axis_name",
  { data_type => "text", is_nullable => 1 },
  "indicator_id",
  { data_type => "integer", is_nullable => 1 },
  "indicator_name",
  { data_type => "text", is_nullable => 1 },
  "formula_human",
  { data_type => "text", is_nullable => 1 },
  "formula_explanation",
  { data_type => "text", is_nullable => 1 },
  "formula",
  { data_type => "text", is_nullable => 1 },
  "nossa_leitura",
  { data_type => "text", is_nullable => 1 },
  "period",
  { data_type => "text", is_nullable => 1 },
  "valid_from",
  { data_type => "date", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "user_goal",
  { data_type => "text", is_nullable => 1 },
  "institute_id",
  { data_type => "integer", is_nullable => 1 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "region_id",
  { data_type => "integer", is_nullable => 1 },
  "sources",
  { data_type => "character varying[]", is_nullable => 1 },
  "region_name",
  { data_type => "text", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "values_used",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-07-21 20:11:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/YDojsVjBhceqoCq3yhHwA

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
