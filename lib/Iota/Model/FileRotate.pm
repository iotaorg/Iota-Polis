package Iota::Model::FileRotate;
use Moose;
use utf8;
use JSON qw/encode_json/;

use Iota::Model::File::XLS_Rotate;
use Text::Unaccent::PurePerl;

sub process {
    my ( $self, %param ) = @_;

    my $upload = $param{upload};
    my $schema = $param{schema};

    my $parse;
    eval {
        if ( $upload->filename =~ /xls$/ ) {
            $parse = Iota::Model::File::XLS_Rotate->new->parse( $upload->tempname );
        }
    };
    die $@ if $@;
    die "file not supported!\n" unless $parse;

    my %regsids =
      map { $_->{region_id} => 1 } grep { $_->{region_id} } @{ $parse->{rows} };
    my @regs_db =
      $schema->resultset('Region')
      ->search( { id => { in => [ keys %regsids ] } }, { select => [qw/id depth_level/], as => [qw/id depth_level/] } )
      ->as_hashref->all;
    my %reg_vs_id = map { $_->{id} => $_ } @regs_db;

    if ( scalar keys %regsids != scalar @regs_db ) {
        my $status = '';
        foreach my $id ( keys %regsids ) {
            my $exists = grep { $_->{id} eq $id } @regs_db;

            $status .= "Região ID $id nao existe.\n"
              unless $exists;
        }
        $status .= 'Arrume o arquivo e envie novamente.';

        die $status;
    }

    my %variables = $self->generate_variables(
        variables => $parse->{variables},
        user_id   => $param{user_id},
        rs        => $schema->resultset('Variable'),
        period => $parse->{period},
        type => $parse->{type},

    );

    my $file_id;

    my $status = @{ $parse->{rows} } . ' linhas, ';

    my $user_id = $param{user_id};
    my $file    = $schema->resultset('File')->create(
        {
            name         => $upload->filename,
            status_text  => $status,
            created_by   => $user_id,
            private_path => $param{private_path},
            public_path  => $param{public_path},
        }
    );
    $file_id = $file->id;

    my $rvv_rs = $schema->resultset('RegionVariableValue');

    $schema->txn_do(
        sub {
            my $with_region    = {};
            my $without_region = {};
            my $cache_ref      = {};

            # percorre as linhas e insere no banco
            # usando o modelo certo.
            my ( $inserted, $removed ) = ( 0, 0 );

            foreach my $r ( @{ $parse->{rows} } ) {
                while ( my ( $varname, $value ) = each %{ $r->{vars} } ) {

                    # $r->{value} = $self->_verify_variable_type( $r->{value}, $type );

                    next if !defined $value || $value eq '';
                    if ( $value eq '-' ) {

                        # TODO: procurar pela data certa.
                        $removed++
                          if $rvv_rs->search(
                            {
                                region_id     => $r->{region_id},
                                user_id       => $user_id,
                                value_of_date => $r->{date},
                                variable_id   => $variables{$varname},
                            }
                          )->delete > 0;

                        next;
                    }
                    $inserted++;

                    my $ref = {
                        do_not_calc => 1,
                        cache_ref   => $cache_ref
                    };
                    $ref->{variable_id}   = $variables{$varname};
                    $ref->{user_id}       = $user_id;
                    $ref->{value}         = $value;
                    $ref->{value_of_date} = $r->{date};
                    $ref->{file_id}       = $file_id;

                    $ref->{source} = $r->{source};

                    $ref->{region_id} = $r->{region_id};

                    $with_region->{variables}{ $ref->{variable_id} } = 1;
                    $with_region->{dates}{ $r->{date} }              = 1;
                    $with_region->{regions}{ $r->{region_id} }       = 1;

                    # TODO fix this decade...
                    eval { $rvv_rs->_put( $parse->{period}, %$ref ); };

                    die $@ if $@;
                }
            }

            my $data = Iota::IndicatorData->new( schema => $schema->schema );
            if ( exists $with_region->{dates} ) {
                $data->upsert(
                    indicators =>
                      [ $data->indicators_from_variables( variables => [ keys %{ $with_region->{variables} } ] ) ],
                    dates      => [ keys %{ $with_region->{dates} } ],
                    regions_id => [ keys %{ $with_region->{regions} } ],
                    user_id    => $user_id
                );
            }

            $status .= "valores atualizados: $inserted, valores removidos: $removed";

        }
    );
    $file->update( { status_text => $status } );

    return {
        status  => $status,
        file_id => $file_id
    };

}

sub _verify_variable_type {
    my ( $self, $value, $type ) = @_;

    return $value if $type eq 'str';

    # certo, entao agora o type é int ou num.

    # vamos tratar o caso mais comum, que é [0-9]{1,3}\.[0-9]{1,3},[0-9]
    if ( $value =~ /[0-9]{1,3}\.[0-9]{1,3},[0-9]{1,9}$/ ) {
        $value =~ s/\.//g;
        $value =~ s/,/./;
    }

    # valores só com virgula.. eh . no banco..
    elsif ( $value =~ /^[0-9]{1,15},[0-9]{1,9}$/ ) {

        $value =~ s/,/./;
    }

    # e agora o inverso... usou , e depois um .
    elsif ( $value =~ /[0-9]{1,3}\,[0-9]{1,3}.[0-9]{1,9}$/ ) {
        $value =~ s/,//g;
        $value =~ s/\./,/;
    }

    # se parece com numero ?
    if ( $value =~ /^[0-9]{1,15}\.[0-9]{1,9}$/ || $value =~ /^[0-9]{1,15}$/ ) {

        $value = int($value) if $type eq 'int';

        return $value;
    }

    # retorna undef.
    undef();
}

sub generate_variables {
    my ( $self, %opt ) = @_;

    my $var_vs_id;
    my %seen_cognomens;
    foreach my $var ( @{ $opt{variables} } ) {

        my ( $line1, $line2 ) = split /\n/, $var;
        die 'Faltando segunda linha em "' . $var . '"' unless $line2;
        $line2 = unac_string $line2;
        my $cognomen = uc $line2;

        $cognomen =~ s/[^A-Z0-9 ]//g;
        $cognomen =~ s/\s\s*/_/g;
        $cognomen =~ s/ /_/g;
        if ( exists $seen_cognomens{$cognomen} ) {
            die "Apelido $cognomen visto duas vezes no mesmo arquivo com nomes diferentes;"
              . "('$seen_cognomens{$cognomen}' e '$line1').. Favor conferir e enviar novamente.\n";
        }
        $seen_cognomens{$cognomen} = $line1;

        my $vardef = $opt{rs}->search( { cognomen => $cognomen } )->next;

        $var_vs_id->{$var} = $vardef ? $vardef->id : $opt{rs}->create(
            {
                name        => $line1,
                explanation => $line1,
                cognomen    => $cognomen,
                user_id     => $opt{user_id},
                type        => $opt{type},
                period      => $opt{period},

            }
        )->id;
    }

    return wantarray ? %$var_vs_id : $var_vs_id;
}

1;
