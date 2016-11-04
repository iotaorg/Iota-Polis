-- Deploy iota:0079-force-overwrite to pg
-- requires: 0078-fix-order

BEGIN;

alter table institute add column user_overwrite_computerized boolean NOT NULL DEFAULT false;

COMMIT;
