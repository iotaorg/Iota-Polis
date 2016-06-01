-- Deploy iota:0068-tags to pg
-- requires: 0067-polis-init-schema

BEGIN;

alter table network add column tags varchar;

alter table network add column indexable_text tsvector;

COMMIT;
