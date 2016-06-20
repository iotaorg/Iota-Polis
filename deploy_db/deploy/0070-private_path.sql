-- Deploy iota:0070-private_path to pg
-- requires: 0069-ts-vecotr

BEGIN;

alter table file add column private_path varchar;
alter table file add column public_path varchar;

COMMIT;
