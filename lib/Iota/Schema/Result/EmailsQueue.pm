use utf8;
package Iota::Schema::Result::EmailsQueue;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Iota::Schema::Result::EmailsQueue

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

=head1 TABLE: C<emails_queue>

=cut

__PACKAGE__->table("emails_queue");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'emails_queue_id_seq'

=head2 to

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 template

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 subject

  data_type: 'varchar'
  is_nullable: 0
  size: 300

=head2 variables

  data_type: 'text'
  is_nullable: 0

=head2 sent

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 text_status

  data_type: 'text'
  is_nullable: 1

=head2 sent_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "emails_queue_id_seq",
  },
  "to",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "template",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "subject",
  { data_type => "varchar", is_nullable => 0, size => 300 },
  "variables",
  { data_type => "text", is_nullable => 0 },
  "sent",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "text_status",
  { data_type => "text", is_nullable => 1 },
  "sent_at",
  { data_type => "timestamp", is_nullable => 1 },
  "created_at",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-05-27 18:12:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S2BBQ6hFuUA3uQhRBpzIRw

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
