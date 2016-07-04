delete from region;



SELECT setval('public.region_id_seq', 1000, true);


delete from city where id !=1;

update city set name = 'sistema polis' where id=1;

update axis set name = 'Editar valores por indicador' where id=1;

delete from network_user where user_id !=1 ;
delete from user_role where user_id !=1 ;
delete from "user" where id !=1 ;


insert into region (id, name, name_url, city_id, depth_level, subregions_valid_after ,created_by)
values (1, 'São Paulo', 'sao-paulo', 1, 1, '1800-01-01',1);


insert into region (id, name, name_url, city_id, depth_level, subregions_valid_after, upper_region,created_by )
values (100, 'Litoral Norte', 'LN', 1, 2, '1800-01-01', 1,1),
(101, 'São Sebastião', 'sao-sebastiao',1,3,'1800-01-01', 100,1),
(102, 'Ilhabela', 'ilhabela',1,3,'1800-01-01', 100,1),
(103, 'Caraguatatuba', 'caraguatatuba',1,3,'1800-01-01', 100,1),
(104, 'Ubatuba', 'ubatuba',1,3,'1800-01-01', 100,1);


insert into region (id, name, name_url, city_id, depth_level, subregions_valid_after, upper_region,created_by )
values
 (200, 'Baixada Santista', 'BS', 1, 2, '1800-01-01', 1,1),
(201, 'Peruíbe', 'peruibe',1,3,'1800-01-01', 200,1),
(202, 'Itanhaém', 'itanhaem',1,3,'1800-01-01', 200,1),
(203, 'Mongaguá', 'mongagua',1,3,'1800-01-01', 200,1),
(204, 'Praia Grande', 'praia-grande',1,3,'1800-01-01', 200,1),
(205, 'São Vicente', 'sao-vicente',1,3,'1800-01-01', 200,1),
(206, 'Santos', 'santos',1,3,'1800-01-01', 200,1),
(207, 'Cubatão', 'cubatao',1,3,'1800-01-01', 200,1),
(208, 'Guarujá', 'guaruja',1,3,'1800-01-01', 200,1),
(209, 'Bertioga', 'bertioga',1,3,'1800-01-01', 200,1);

update "user" set city_id = 1, institute_id = 1 where id=1;

delete from indicator_value ;
delete from region_variable_value;


update region set id = 3550704  where id = 101;
update region set id = 3520400  where id = 102;
update region set id = 3510500  where id = 103;
update region set id = 3555406  where id = 104;
update region set id = 3537602  where id = 201;
update region set id = 3522109  where id = 202;
update region set id = 3531100  where id = 203;
update region set id = 3541000  where id = 204;
update region set id = 3551009  where id = 205;
update region set id = 3548500  where id = 206;
update region set id = 3513504  where id = 207;
update region set id = 3518701  where id = 208;
update region set id = 3506359  where id = 209;

ALTER TABLE region DROP CONSTRAINT region_fk_upper_region;

update region set id = 351  where id = 1;
update region set upper_region = 351   where upper_region=1;

update region set id = 35063  where id = 200;
update region set upper_region = 35063  where upper_region=200;

update region set id = 35054  where id = 100;
update region set upper_region = 35054  where upper_region=100;

ALTER TABLE region
  ADD CONSTRAINT region_fk_upper_region FOREIGN KEY (upper_region)
      REFERENCES region (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;

