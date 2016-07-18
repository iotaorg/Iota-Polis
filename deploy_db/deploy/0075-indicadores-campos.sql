-- Deploy iota:0075-indicadores-campos to pg
-- requires: 0074-region-order

BEGIN;

alter table indicator add append_on_result varchar;
alter table indicator add prepend_on_result varchar;

alter table indicator add graph_type varchar;

COMMIT;
