use utf8;
package Iota::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-05-27 18:12:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qA1+OpZC2mzGrXTME09Wcg

sub AUTOLOAD {
    ( my $name = our $AUTOLOAD ) =~ s/.*:://;
    no strict 'refs';

    # isso cria na hora a sub e não é recompilada \m/ perl nao é lindo?!
    *$AUTOLOAD = sub {
        my ( $self, @args ) = @_;
        my $res = eval {
            $self->storage->dbh->selectrow_hashref( "select * from $name ( " . substr( '?,' x @args, 0, -1 ) . ')',
                undef, @args );
        };
        do { print STDERR $@; return undef } if $@;
        return $res;
    };
    goto &$AUTOLOAD;
}

sub get_weeks_of_year {
    my ( $self, $year ) = @_;
    my $res = eval {
        $self->storage->dbh->selectall_arrayref(
            "SELECT * FROM (
            SELECT extract('week' from period_begin + '1 day'::interval) as week_num, period_begin
            FROM (
                select (date_trunc('week', (? || '-01-01')::date + s.a + '1 day'::interval) - '1 day'::interval)::date as period_begin
                from generate_series(0,371,7) as s(a)
            ) a
            where a.period_begin >= (? || '-01-01')::date AND a.period_begin < (? || '-01-01')::date + '1 year'::interval
        ) a
        WHERE NOT (week_num = 1 AND period_begin > (? || '-12-01')::date )  -- semana 01 do proximo ano
        ORDER BY a.period_begin
        ", { Slice => {} }, $year, $year, $year, $year
        );
    };
    do { print STDERR $@; print $@; return undef } if $@;

    return $res;
}

sub f_compute_all_upper_regions {
    my ($self) = @_;
    my $res = eval {
        $self->storage->dbh->selectall_arrayref(
"SELECT compute_upper_regions( ARRAY(select id from region where depth_level = 3 )::int[], null, null, null, 3 );
        ", { Slice => {} }
        );
    };
    do { print STDERR $@; die $@; return undef } if $@;

    return $res;
}

sub period_to_rdf {
    my ( $self, $period ) = @_;
    return {
        qw|
          daily        http://purl.org/cld/freq/daily
          weekly       http://purl.org/cld/freq/weekly
          monthly      http://purl.org/cld/freq/monthly
          bimonthly    http://purl.org/cld/freq/bimonthly
          quarterly    http://purl.org/cld/freq/quarterly
          semi-annual  http://purl.org/cld/freq/semiannual
          yearly       http://purl.org/cld/freq/annual
          decade       http://purl.org/cld/freq/irregular
          |
    }->{$period};

}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
