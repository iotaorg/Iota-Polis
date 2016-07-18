-- Deploy iota:0074-region-order to pg
-- requires: 0073-new-perido

BEGIN;

alter table region add column display_order int;

update region set display_order = id;

update region set display_order = id;

update region set display_order=20-01 where name ilike '%Ubatuba%';
update region set display_order=20-02 where name ilike '%Caraguatatuba%';
update region set display_order=20-03 where name ilike '%Ilhabela%';
update region set display_order=20-04 where name ilike '%São% Sebastião';
update region set display_order=20-05 where name ilike '%Bertioga%';
update region set display_order=20-06 where name ilike '%Guarujá%';
update region set display_order=20-07 where name ilike '%Santos%';
update region set display_order=20-08 where name ilike '%Cubatão%';
update region set display_order=20-09 where name ilike '%São% Vicente';
update region set display_order=20-10 where name ilike '%Praia% Grande';
update region set display_order=20-11 where name ilike '%Mongaguá%';
update region set display_order=20-12 where name ilike '%Itanhaém%';
update region set display_order=20-13 where name ilike '%Peruíbe%';

update region set display_order=10000000 where name ilike '%Litoral Sustentável%';



COMMIT;
