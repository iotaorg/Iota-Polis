-- Deploy iota:0074-region-order to pg
-- requires: 0073-new-perido

BEGIN;

alter table region add column display_order int;

update region set display_order = id;

update region set display_order = id;

update region set display_order=01 where name ilike '%Ubatuba%';
update region set display_order=02 where name ilike '%Caraguatatuba%';
update region set display_order=03 where name ilike '%Ilhabela%';
update region set display_order=04 where name ilike '%São% Sebastião';
update region set display_order=05 where name ilike '%Bertioga%';
update region set display_order=06 where name ilike '%Guarujá%';
update region set display_order=07 where name ilike '%Santos%';
update region set display_order=08 where name ilike '%Cubatão%';
update region set display_order=09 where name ilike '%São% Vicente';
update region set display_order=10 where name ilike '%Praia% Grande';
update region set display_order=11 where name ilike '%Mongaguá%';
update region set display_order=12 where name ilike '%Itanhaém%';
update region set display_order=13 where name ilike '%Peruíbe%';

COMMIT;
