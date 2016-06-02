-- Deploy iota:0069-ts-vecotr to pg
-- requires: 0068-tags

BEGIN;

CREATE OR REPLACE FUNCTION network_vector_update() RETURNS TRIGGER AS $$
BEGIN

    NEW.indexable_text =
     setweight(to_tsvector('pg_catalog.portuguese', COALESCE(NEW.name, '') ||' '|| COALESCE(NEW.tags, '') ), 'A') ||
     setweight(to_tsvector('pg_catalog.portuguese', COALESCE(NEW.description, '') ), 'B');

    RETURN NEW;
END
$$ LANGUAGE 'plpgsql';


CREATE TRIGGER tsvectorupdate_network BEFORE INSERT OR UPDATE ON network
FOR EACH ROW EXECUTE PROCEDURE network_vector_update();
update network set id=id;

COMMIT;
