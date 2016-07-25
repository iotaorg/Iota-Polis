-- Deploy iota:0077-indicator_order to pg
-- requires: 0076-new-download

BEGIN;

alter table indicator add column display_order int not null default 0;


COMMIT;
