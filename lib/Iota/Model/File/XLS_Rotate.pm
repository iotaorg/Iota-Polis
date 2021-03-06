package Iota::Model::File::XLS_Rotate;
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
        date      => qr /\bdata\b/io,
        source    => qr /\bfonte\b/io,
        start_var => qr /^(startvar|id.variavel)$/io,
        region_id => qr /\b(id da regi.o|regi.o id|id.ibge)\b/io,
    );

    my @rows;
    my $ignored = [];
    my $header_found;
    my $total_vars;
    my $period = 'century';
    my $type   = 'str';
    my $start_var_evalued;
    while ( my $sheet = $xls->sheet() ) {
        my $aba = eval { $sheet->name } || 'aba desconhecida';
        my $header_map = {};
        my $variables  = {};
        $header_found = 0;

        my $row_num = 0;
        while ( my $row = $sheet->row ) {

            $row_num++;

            my @data = @$row;

            if ( !$header_found ) {
                for my $col ( 0 .. ( scalar @data - 1 ) ) {

                    my $cell = $data[$col];
                    next unless $cell;

                    foreach my $header_name ( keys %expected_header ) {

                        if ( !exists $header_map->{$header_name} && $cell =~ $expected_header{$header_name} ) {
                            $header_found++;
                            $header_map->{$header_name} = $col;
                        }
                    }
                }

                if ($header_found) {
                    die "Faltando coluna fonte\n"     unless exists $header_map->{source};
                    die "Faltando coluna data\n"      unless exists $header_map->{date};
                    die "Faltando coluna Região\n"   unless exists $header_map->{region_id};
                    die "Faltando coluna start_var\n" unless exists $header_map->{start_var};

                    for my $col ( $header_map->{start_var} + 1 .. ( scalar @data - 1 ) ) {

                        my $cell = $data[$col];
                        next unless $cell;

                        $cell = decode( 'iso-8859-15', $cell );
                        $cell =~ s/\s*$//o;
                        $cell =~ s/^\s*//o;
                        $cell =~ s/  */ /go;

                        $variables->{$cell}  = $col;
                        $total_vars->{$cell} = 1;
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

                if (   exists $registro->{region_id}
                    && exists $registro->{date}
                    && $registro->{source} ) {

                    $registro->{date} =
                        $registro->{date} =~ /^20[0123][0-9]$/       ? $registro->{date} . '-01-01'
                      : $registro->{date} =~ /^\d{4}\-\d{2}\-\d{2}$/ ? $registro->{date}
                      :   DateTime::Format::Excel->parse_datetime( $registro->{date} )->ymd;

                    die "Data invalida: " . $registro->{date} unless $registro->{date} =~ /\d{4}-\d{2}-\d{2}/;
                    die 'Região Invalida' if $registro->{region_id} && $registro->{region_id} !~ /^\d+$/;

                    foreach my $varname ( keys %$variables ) {
                        $registro->{vars}{$varname} = $data[ $variables->{$varname} ];
                    }

                    push @rows, $registro;

                    if ( !$start_var_evalued && exists  $registro->{start_var} && $registro->{start_var} =~ /^(num|str|int)\/(yearly|decade|century)$/i )
                    {
                        $type              = lc $1;
                        $period            = lc $2;
                        $start_var_evalued = 1;
                    }

                }
                else {

                    push @{$ignored}, "'$aba' linha $row_num";
                }

            }
        }
    }

    die "cabecalho nao encontrado" unless \@rows;

    return {
        rows      => \@rows,
        ignored   => $ignored,
        variables => [ keys %$total_vars ],
        period    => $period,
        type      => $type

    };
}

1;
