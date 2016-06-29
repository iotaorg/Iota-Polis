-- Deploy iota:0072-unnac to pg
-- requires: 0071-colors
CREATE EXTENSION unaccent;
BEGIN;


CREATE OR REPLACE FUNCTION network_vector_update() RETURNS TRIGGER AS $$
BEGIN

    NEW.indexable_text =
     setweight(to_tsvector('pg_catalog.portuguese', COALESCE(unaccent(NEW.name), '') ||' '|| COALESCE(unaccent(NEW.tags), '') ), 'A') ||
     setweight(to_tsvector('pg_catalog.portuguese', COALESCE(unaccent(NEW.description), '') ), 'B');

    RETURN NEW;
END
$$ LANGUAGE 'plpgsql';

update network set id=id;

COMMIT;
