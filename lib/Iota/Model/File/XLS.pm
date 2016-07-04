package Iota::Model::File::XLS;
use strict;
use Moose;
use utf8;
use DateTime;
use DateTime::Format::Pg;

use Spreadsheet::ParseExcel::Stream;
use DateTime::Format::Excel;

use Encode;

sub parse {
    my ( $self, $file ) = @_;

    my $xls = Spreadsheet::ParseExcel::Stream->new($file);

    my %expected_header = (
        id      => qr /\b(id da v.ri.vel|v.ri.vel id)\b/io,
        date    => qr /\bdata\b/io,
        value   => qr /\bvalor\b/io,
        apelido => qr /\b(apelido)\b/io,
        obs     => qr /\bobserva..o\b/io,
        source  => qr /\bfonte\b/io,

        region_id => qr /\b(id da regi.o|regi.o id|id_ibge)\b/io,
    );

    my @rows;
    my $ok      = 0;
    my $ignored = 0;
    my $header_found;
    while ( my $sheet = $xls->sheet() ) {
        my $sheet_name = $sheet->name;
        my $header_map = {};
        $header_found = 0;

        my $linenum = 0;
        while ( my $row = $sheet->row ) {
            $linenum++;

            my @data = @$row;

            if ( !$header_found ) {

                for my $col ( 0 .. ( scalar @data - 1 ) ) {
                    my $cell = $data[$col];
                    next unless $cell;

                    foreach my $header_name ( keys %expected_header ) {

                        if ( $cell =~ $expected_header{$header_name} ) {
                            $header_found++;
                            $header_map->{$header_name} = $col;
                        }
                    }
                }
            }
            else {

                # aqui você pode verificar se foram encontrados todos os campos que você precisa
                # neste caso, achar apenas 1 cabeçalho já é o suficiente

                my $registro = {};

                foreach my $header_name ( keys %$header_map ) {
                    my $col = $header_map->{$header_name};

                    my $value = $data[$col];

                    # aqui é uma regra que você escolhe, pois as vezes o valor da célula pode ser nulo
                    next if !defined $value || $value =~ /^\s*$/;
                    $value =~ s/^\s+//;
                    $value =~ s/\s+$//;

                    $value = decode( 'iso-8859-15', $value );
                    $registro->{$header_name} = $value;
                }

                if (   ( exists $registro->{id} || $registro->{apelido} )
                    && exists $registro->{date}
                    && exists $registro->{value}
                    && $registro->{region_id} ) {

                    my $data_antes = $registro->{date};
                    $registro->{date} =~ s|^(\d)/(\d)/(\d{2})$|20$3-0$2-0$1|;
                    $registro->{date} =~ s|^(\d)/(\d)/(\d{4})$|$3-0$2-0$1|;
                    $registro->{date} =~ s|^(\d\d)/(\d\d)/(\d{2})$|20$3-$2-$1|;
                    $registro->{date} =~ s|^(\d\d)/(\d\d)/(\d{4})$|$3-$2-$1|;

                    $registro->{date} =
                        $registro->{date} =~ /^20[0123][0-9]$/       ? $registro->{date} . '-01-01'
                      : $registro->{date} =~ /^\d{4}\-\d{2}\-\d{2}$/ ? $registro->{date}
                      :   eval { DateTime::Format::Excel->parse_datetime( $registro->{date} )->ymd };
                    if ($@) {
                        die "problemas para entender a data '$data_antes' na linha $linenum '$sheet_name' \n";
                    }
                    $ok++;

                    use DDP; p $registro;
                    die "o apelido 0.00E+00 provavlmente eh um engano na linha $linenum '$sheet_name' \n"
                      if exists $registro->{apelido} && $registro->{apelido} eq '0.00E+00';

                    do { die 'id de variavel precisa ser numerico' unless $registro->{id} =~ /^\d+$/ }
                      if $registro->{id};
                    die 'regiao precisa ser numerico' if $registro->{region_id} && $registro->{region_id} !~ /^\d+$/;

                    push @rows, $registro;

                }
                else {

                    use DDP; p $registro;
                    $ignored++;
                }

            }
        }
    }

    return {
        rows         => \@rows,
        ignored      => $ignored,
        ok           => $ok,
        header_found => !!$header_found
    };
}

1;
