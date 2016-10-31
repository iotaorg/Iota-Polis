-- Deploy iota:0078-fix-order to pg
-- requires: 0077-indicator_order

BEGIN;

update region set display_order = 520 where id = 35054;

update region set display_order = display_order + 200 where upper_region = 35054;
update region set display_order = display_order + 200 where upper_region = 35054;

COMMIT;
