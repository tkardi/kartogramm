/* BOUNDARIES */

truncate table vectiles.boundaries;

insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    x.geom, null as originalid, x.left_a3, x.right_a3,
    case
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTA'
        when x.left_country_code = 'RU' then 'RUS'
        else null
    end as country_left,
    case
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTA'
        when x.right_country_code = 'RU' then 'RUS'
        else null
    end as country_right,
    'settlement'::vectiles.type_boundaries,
    'settlement.'::vectiles.subtype_boundaries,
    false as on_water
from vectiles_input.baltic_admin x
where x.left_a3 is not null or x.right_a3 is not null
;


insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    (st_dump(st_linemerge(st_collect(x.geom)))).geom, null as originalid,
    x.left_a2, x.right_a2,
    case
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTA'
        when x.left_country_code = 'RU' then 'RUS'
        else null
    end as country_left,
    case
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTA'
        when x.right_country_code = 'RU' then 'RUS'
        else null
    end as country_right,
    'municipality'::vectiles.type_boundaries,
    'municipality.'::vectiles.subtype_boundaries,
    false as on_water
from vectiles_input.baltic_admin x
where coalesce(x.left_a2, '-1') != coalesce(x.right_a2, '-1')
group by x.left_a2, x.right_a2, x.left_country_code, x.right_country_code
;

insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    (st_dump(st_linemerge(st_collect(x.geom)))).geom, null as originalid,
    x.left_a1, x.right_a1,
    case
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTA'
        when x.left_country_code = 'RU' then 'RUS'
        else null
    end as country_left,
    case
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTA'
        when x.right_country_code = 'RU' then 'RUS'
        else null
    end as country_right,
    'province'::vectiles.type_boundaries,
    'province.'::vectiles.subtype_boundaries,
    false as on_water
from vectiles_input.baltic_admin x
where coalesce(x.left_a1, '-1') != coalesce(x.right_a1, '-1')
group by x.left_a1, x.right_a1, x.left_country_code, x.right_country_code
;

insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    (st_dump(st_linemerge(st_collect(x.geom)))).geom,
    null as originalid,
    case
        when x.left_country_code = 'EE' then 'Eesti'
        when x.left_country_code = 'LV' then 'Läti'
        when x.left_country_code = 'LT' then 'Leedu'
        when x.left_country_code = 'RU' then 'Venemaa'
        else null
    end as name_left,
    case
        when x.right_country_code = 'EE' then 'Eesti'
        when x.right_country_code = 'LV' then 'Läti'
        when x.right_country_code = 'LT' then 'Leedu'
        when x.right_country_code = 'RU' then 'Venemaa'
        else null
    end as name_right,
    case
        when x.left_country_code = 'EE' then 'EST'
        when x.left_country_code = 'LV' then 'LVA'
        when x.left_country_code = 'LT' then 'LTA'
        when x.left_country_code = 'RU' then 'RUS'
        else null
    end as country_left,
    case
        when x.right_country_code = 'EE' then 'EST'
        when x.right_country_code = 'LV' then 'LVA'
        when x.right_country_code = 'LT' then 'LTA'
        when x.right_country_code = 'RU' then 'RUS'
        else null
    end as country_right,
    'country'::vectiles.type_boundaries,
    case
        when 'EE' = any(array[left_country_code, right_country_code]) then 'country.domestic'
        else 'country.foreign'
    end::vectiles.subtype_boundaries as subtype,
    false as on_water
from vectiles_input.baltic_admin x
where coalesce(x.left_country_code, '-1') != coalesce(x.right_country_code, '-1')
group by x.left_a1, x.right_a1, x.left_country_code, x.right_country_code
;


insert into vectiles.boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    (st_dump(st_linemerge(st_collect(geom)))).geom as geom, null as originalid,
    left_name as name_left,
    right_name as name_right,
    case
        when left_country_code = 'RU' then 'RUS'
        when left_country_code = 'EE' then 'EST'
        when left_country_code = 'LV' then 'LVA'
        when left_country_code = 'LT' then 'LTU'
		else null
    end as country_left,
    case
        when right_country_code = 'RU' then 'RUS'
        when right_country_code = 'EE' then 'EST'
        when right_country_code = 'LV' then 'LVA'
        when right_country_code = 'LT' then 'LTU'
		else null
    end as country_right,
    'country'::vectiles.type_boundaries as type,
    case
        when 'EE' = any(array[left_country_code, right_country_code]) then 'country.domestic'
        else 'country.foreign'
    end::vectiles.subtype_boundaries as subtype,
    on_water
from
    vectiles_input.baltic_a0_expanded
group by
    left_name, right_name, left_country_code, right_country_code, on_water
;
