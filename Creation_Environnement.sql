CREATe TABLE lieux(nom text primary key, point geometry(point,4326), classe text);
--delete from lieux where nom = 'Gizeh';
insert into lieux(nom,point) values ('Angkor_Vat',ST_setsrid('POINT(103.8668 13.41249)'::geometry,4326));
--insert into lieux(nom,point) values ('Cuzco',ST_setsrid('POINT(-71.972222 -13.525)'::geometry,4326));
insert into lieux(nom,point) values ('KhaJuraho',ST_setsrid('POINT(79.93 24.85)'::geometry,4326));
insert into lieux(nom,point) values ('Gizeh',ST_setsrid('POINT(31.134352 29.979239)'::geometry,4326));
insert into lieux(nom,point) values ('Machu Piccu',ST_setsrid('POINT(-72.54583 -13.1639)'::geometry,4326));
insert into lieux(nom,point) values ('Mohen-Jo-Daro',ST_setsrid('POINT(68.137211 27.326851)'::geometry,4326));

insert into lieux(nom,point) values ('Nasca',ST_setsrid('POINT(-75.133333 -14.716667 )'::geometry,4326));
insert into lieux(nom,point) values ('Ollantaytambo',ST_setsrid('POINT(-72.26333 -13.25806)'::geometry,4326));

insert into lieux(nom,point) values ('Paques',ST_setsrid('POINT(-109.4088546 -27.1259626)'::geometry,4326));
insert into lieux(nom,point) values ('Paratoari',ST_setsrid('POINT(-71.4612 -12.673164)'::geometry,4326));
insert into lieux(nom,point) values ('Paracas',ST_setsrid('POINT(-76.305028 -13.795056)'::geometry,4326));
insert into lieux(nom,point) values ('Persepolis',ST_setsrid('POINT(52.891389 29.934444)'::geometry,4326));

insert into lieux(nom,point) values ('Petra',ST_setsrid('POINT(35.44361 30.32917)'::geometry,4326));
insert into lieux(nom,point) values ('Preah_Vihear',ST_setsrid('POINT(104.68389 14.38833)'::geometry,4326));

insert into lieux(nom,point) values ('Pyay',ST_setsrid('POINT(95.217 18.817)'::geometry,4326));
insert into lieux(nom,point) values ('Sacsayhuamán',ST_setsrid('POINT(-71.982222 -13.507778)'::geometry,4326));
insert into lieux(nom,point) values ('Siwa',ST_setsrid('POINT(25.55 29.183333)'::geometry,4326));

insert into lieux(nom,point) values ('Sukhotail',ST_setsrid('POINT(99.78972 17.00722)'::geometry,4326));

insert into lieux(nom,point) values ('Tassili n Ajjer',ST_setsrid('POINT(8.166667 25.166667)'::geometry,4326));
insert into lieux(nom,point) values ('UR',ST_setsrid('POINT(46.10551 30.961243)'::geometry,4326));


CREATE TABLE nombre_a_tester
(
  idn integer NOT NULL DEFAULT nextval('nombre_a_tester_idn_seq'::regclass),
  nombre double precision,
  isspecial boolean,
  CONSTRAINT nombre_a_tester_pkey PRIMARY KEY (idn)
);

with rnd(r) as 
(select r FROM (select random()*10 as r from generate_series(1,1000)) t order by r),
specials as (
	select * from (values  (1,TRUE), (1.61803399, TRUE), (3.14159265, TRUE) ) as t
)
Insert into nombre_a_tester(nombre,isspecial) 
select r, bool from
(select r, false as bool FROM rnd
UNION ALL
select * from specials) as t order by r;



drop table Resultats_statistiques_rapport_distanceHasard;
create Table Resultats_statistiques_rapport_distanceHasard(idr serial, nombre_teste float, nb_km_marge_ecart integer, nombre_echantillon integer, moyenne float, ecart_type FLOAT,
       							   isLRDP Boolean, angle_equateur_penche Float CONSTRAINT resultats_statistiques_rapport_distance_pkey PRIMARY KEY (idr));

CREATE OR REPLACE FUNCTION generestatistiqueslrdpechantillonshasard(
    km_max integer,
    pas_km integer,
    facteur_multiplicatif_distance_a_tester double precision,
    nbr_echantillon integer,
    angle_equateur_penche Float
)
  RETURNS boolean AS
$BODY$
	DECLARE
		i integer;	
	BEGIN

		Create Table Tmp_Stat(nb_km integer, match_count integer, serie integer);
		
		FOR i in 1 .. nbr_echantillon LOOP
			-- On lance le calcul

			WITH gen(fact) as (
			 select generate_series(1,km_max/pas_km)
			), faussetbllieux as (--30.64° => 0.534768882811063
			select left(md5(random()::text),6) as nom, ST_SetSRID(ST_MakePoint(degrees(X),degrees(angle_equateur_penche*sin(angle_equateur_penche*X)) ),4326) as point from ( 
				select x from ( select radians(random()*360-180) as x from generate_series(1,75) ) t
				where x not between  -0.785398163397448 and -0.331612557878923 and x not between -1.90520141147701 and -1.32645023151569 and 
				x not between -3.14159265358979 and -1.91131006385899 and x not between 2.23402144255274 and 3.14159265358979 limit 17 ) VingtX
			), t1 as (
			select l1.nom as n1, l2.nom as n2, l3.nom as n3, st_distance(l1.point, l2.point,true) as dist1,  st_distance(l2.point, l3.point,true) as dist2, st_distance(l1.point, l3.point,true) as dist3
			from faussetbllieux l1, faussetbllieux l2, faussetbllieux l3
			 where l1.nom not like l2.nom and l2.nom not like l3.nom and l1.nom not like l3.nom
			), t2  as (
			select distinct abs(dist1 - facteur_multiplicatif_distance_a_tester*dist2) as diffdist, fact from t1, gen  where dist1 > 150000 and dist2 > 150000 and dist3 > 150000 --150km
			and abs(dist1 - facteur_multiplicatif_distance_a_tester*dist2) < pas_km*1000*fact
			)
			insert into Tmp_Stat(nb_km, match_count, serie) 
				select fact*pas_km as nb_km, count(diffdist), i from t2 group by fact order by fact;
			
		END LOOP;
		Insert into Resultats_statistiques_rapport_distanceHasard(nombre_teste, nb_km_marge_ecart, nombre_echantillon, moyenne, ecart_Type, isLRDP, angle_equateur_penche)
			select facteur_multiplicatif_distance_a_tester, nb_km, nbr_echantillon, moy, et, false, angle_equateur_penche from 
			( select  nb_km, avg(match_count) as moy, stddev(match_count) as et from Tmp_Stat group by nb_km ) t order by nb_km;
		drop table Tmp_Stat;
		
		
		RETURN true;
	END;
	$BODY$
  LANGUAGE plpgsql VOLATILE STRICT
  COST 10000;


-- Attention !! Calcul durant plusieurs jours !!!

select GenereStatistiquesLRDPEchantillonsHasard(150,1,nombre,500, 0.534768882811063) from nombre_a_tester;


create Table Resultats_statistiques_rapport_distanceLRDP(idr serial, nombre_teste float, nb_km_marge_ecart integer, nombre_site float, 
	CONSTRAINT resultats_statistiques_rapport_distance_LRDP_pkey PRIMARY KEY (idr));



with nombres_a_tester as (
select distinct nombre_teste from Resultats_statistiques_rapport_distance where nombre_teste  order by nombre_teste
),
 gen(fact) as (
 select generate_series(1,150)
),  lieuxNormalise as (
select * from lieux where nom not like 'Ollantaytambo' and nom not like 'Machu Piccu' 
), t1 as (
select l1.nom as n1, l2.nom as n2, l3.nom as n3, st_distance(l1.point, l2.point,true) as dist1,  st_distance(l2.point, l3.point,true) as dist2, st_distance(l1.point, l3.point,true) as dist3
from lieuxNormalise l1, lieuxNormalise l2, lieuxNormalise l3
 where l1.nom not like l2.nom and l2.nom not like l3.nom and l1.nom not like l3.nom
), t2  as (
select distinct nombre_teste, abs(dist1 - nombre_teste*dist2) as diffdist, fact from t1, gen, nombres_a_tester  where 
dist1 > 150000 and dist2 > 150000 and dist3 > 150000 and abs(dist1 - nombre_teste*dist2) < 1000*fact
)
Insert into Resultats_statistiques_rapport_distanceLRDP(nombre_teste, nb_km_marge_ecart, nombre_site)
	select nombre_teste, fact as nb_km, count(diffdist)  as nbsite from t2 group by fact, nombre_teste order by nombre_teste, fact;



create Table Resultats_statistiques_rapport_distanceLRDPFinal(idr serial, nombre_teste float, nb_km_marge_ecart integer, nombre_site float, 
	CONSTRAINT resultats_statistiques_rapport_distance_LRDP_pkey PRIMARY KEY (idr));
create index on Resultats_statistiques_rapport_distanceLRDPFinal(nombre_teste);



-- Requête allambiquée permettant de remplir les "trous" qui surviennent du fait que lorsqu'il y a 0 sites, ils ne sont pas remontés.
insert into Resultats_statistiques_rapport_distanceLRDPFinal(nombre_teste, nb_km_marge_ecart, nombre_site)
(select nombre_teste, nb_km_marge_ecart, 0 as nombre_site
FROM ((with serie(km) as (
select * from  generate_series(1,150)
),
 blancs AS ( select t.nombre_teste, km from (select distinct nombre_teste FROM Resultats_statistiques_rapport_distanceLRDP) t, serie  )
select nombre_teste, km as nb_km_marge_ecart  from blancs)
EXCEPT select nombre_teste, nb_km_marge_ecart from Resultats_statistiques_rapport_distanceLRDP) ASUPPR order by nombre_teste, nb_km_marge_ecart)
UNION
select nombre_teste, nb_km_marge_ecart, nombre_site from Resultats_statistiques_rapport_distanceLRDP order by nombre_teste, nb_km_marge_ecart;

