-- Deploy iota:0068-setup-institutes to pg
-- requires: 0067-polis-init-schema

BEGIN;

delete from user_role where user_id in (select id from "user" where institute_id = 2);
delete from network_user where user_id in (select id from "user" where institute_id = 2);

delete from "user" where institute_id = 2;

delete from network where institute_id = 2;

delete from institute where id = 2;

update institute set name = 'Polis', short_name = 'polis', description ='', users_can_edit_value=true,
users_can_edit_groups=false,
can_use_custom_css=false,
can_use_custom_pages=true,
bypass_indicator_axis_if_custom=true,
hide_empty_indicators=false,
can_use_regions=true,
can_create_indicators=true,
fixed_indicator_axis_id=1,
aggregate_only_if_full=true,
active_me_when_empty=true;

COMMIT;
