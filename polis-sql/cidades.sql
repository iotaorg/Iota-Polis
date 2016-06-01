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
 (200, 'Litoral Sul', 'LS', 1, 2, '1800-01-01', 1,1),
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