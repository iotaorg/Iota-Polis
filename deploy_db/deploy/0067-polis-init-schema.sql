-- Deploy iota:0067-polis-init-schema to pg
-- requires: 0066-fix-download-view

BEGIN;

alter table network add column template_name varchar;
alter table network add column axis_name varchar;
alter table network add column description varchar;

alter table network add column text_content json;

COMMIT;
