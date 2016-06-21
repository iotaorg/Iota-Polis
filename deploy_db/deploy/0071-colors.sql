-- Deploy iota:0071-colors to pg
-- requires: 0070-private_path

BEGIN;

alter table variable add column colors json;

COMMIT;
