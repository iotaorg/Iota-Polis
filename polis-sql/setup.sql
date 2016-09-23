
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


update indicator set axis_id = 1;
update axis set name = 'nao-usado-no-polis' where id = 1;

delete from axis where id > 1;

update "region" set display_order=0 where id = 35063;
update "region" set display_order=216 where id = 3550704;
update "region" set display_order=217 where id = 3520400;
update "region" set display_order=218 where id = 3510500;
update "region" set display_order=219 where id = 3555406;
update "region" set display_order=300 where id = 35054;
update "region" set display_order=407 where id = 3537602;
update "region" set display_order=408 where id = 3522109;
update "region" set display_order=409 where id = 3531100;
update "region" set display_order=410 where id = 3541000;
update "region" set display_order=411 where id = 3551009;
update "region" set display_order=412 where id = 3513504;
update "region" set display_order=413 where id = 3548500;
update "region" set display_order=414 where id = 3518701;
update "region" set display_order=415 where id = 3506359;
update "region" set display_order=10000000 where id = 351;
