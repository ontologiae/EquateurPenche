

with nombres(nb) as (
select nombre_teste as nb from (select distinct nombre_teste, row_number() OVER () as rnum, islrdp from ( select distinct nombre_teste, islrdp FROM Resultats_statistiques_rapport_distance order by nombre_teste) t ) t2
where (mod(rnum,1) = 0  and nombre_teste >= 0) or islrdp = TRUE order by nombre_teste
),
prepMMH as (
select nb, nb_km_marge_ecart as nb_km, moyenne
from Resultats_statistiques_rapport_distance r inner join nombres n on (r.nombre_teste = n.nb) order by nb, nb_km_marge_ecart
),
MMH as (
 select nb, nb_km,   
    case when
        nb_km > 1
    then moyenne-lag(moyenne,1) OVER w
    else 0 end as accroissementH
 from prepMMH window W as (order by nb,nb_km) order by nb,nb_km
),
FinalAcMMH as (
select  nb,case when
        row_number() over (order by nb,nb_km) > 6
        then avg(accroissementH) OVER W 
        else 0 end as MoyMobDiff, accroissementH, nb_km
from MMH window W as (order by nb,nb_km DESC ROWS BETWEEN 0 following AND 6 FOLLOWING)  order by nb,nb_km
),
prepMML as (
select nb, nb_km_marge_ecart as nb_km, nombre_site
from resultats_statistiques_rapport_distancelrdpfinal r inner join nombres n on (r.nombre_teste = n.nb) order by nb, nb_km_marge_ecart
),
MML as (
select nb, nb_km,   
    case when
        nb_km > 1
        then nombre_site-lag(nombre_site,1) OVER w
        else 0 end as accroissementL,
        lag(nombre_site) over w as m1,
        nombre_site
from prepMML window W as (order by nb,nb_km) order by nb,nb_km
),
FinalAcMML as (
select  nb,case when
        row_number() over (order by nb,nb_km) > 6
        then avg(accroissementL) OVER W 
        else 0 end as nbSiteMoyMobDiff, accroissementL, nb_km
from MML window W as (order by nb,nb_km DESC ROWS BETWEEN 0 following AND 6 FOLLOWING)  order by nb,nb_km
)
--select distinct L.nb from FinalAcMML L order by nb
--select L.nb, L.nb_km, nbSiteMoyMobDiff-MoyMobDiff FROM FinalAcMMH H inner join FinalAcMML L on (H.nb = L.nb and H.nb_km = L.nb_km);
select L.nb, max(nbSiteMoyMobDiff-MoyMobDiff) as diffAccMoyMob FROM FinalAcMMH H inner join FinalAcMML L on (H.nb = L.nb and H.nb_km = L.nb_km) group by L.nb Having L.nb > 0.9 order by max(nbSiteMoyMobDiff-MoyMobDiff);
