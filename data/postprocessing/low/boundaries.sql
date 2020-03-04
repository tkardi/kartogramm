/* Z_LOW_BOUNDARIES */

truncate table vectiles.z_low_boundaries restart identity;

with trans as (
    select * from json_to_recordset('[
       {"en":"Austria","ee":"Austria"},
       {"en":"Belarus","ee":"Valgevene"},
       {"en":"Belgium","ee":"Belgia"},
       {"en":"Bosnia and Herzegovina","ee":"Bosnia ja Hertsegoviina"},
       {"en":"Croatia","ee":"Horvaatia"},
       {"en":"Czech Republic","ee":"Tšehhi"},
       {"en":"Denmark","ee":"Taani"},
       {"en":"Estonia","ee":"Eesti"},
       {"en":"Finland","ee":"Soome"},
       {"en":"France","ee":"Prantsusmaa"},
       {"en":"Germany","ee":"Saksamaa"},
       {"en":"Hungary","ee":"Ungari"},
       {"en":"Italy","ee":"Itaalia"},
       {"en":"Latvia","ee":"Läti"},
       {"en":"Liechtenstein","ee":"Lihtenstein"},
       {"en":"Lithuania","ee":"Leedu"},
       {"en":"Luxembourg","ee":"Luksemburg"},
       {"en":"Moldova","ee":"Moldova"},
       {"en":"Netherlands","ee":"Holland"},
       {"en":"Norway","ee":"Norra"},
       {"en":"Poland","ee":"Poola"},
       {"en":"Republic of Serbia","ee":"Serbia"},
       {"en":"Romania","ee":"Rumeenia"},
       {"en":"Russia","ee":"Venemaa"},
       {"en":"Slovakia","ee":"Slovakkia"},
       {"en":"Slovenia","ee":"Sloveenia"},
       {"en":"Sweden","ee":"Rootsi"},
       {"en":"Switzerland","ee":"Šveits"},
       {"en":"Ukraine","ee":"Ukraina"}
]') as x(en text, ee text)
)
insert into vectiles.z_low_boundaries (
    geom, originalid, name_left, name_right, country_left, country_right, type, subtype, on_water
)
select
    (st_dump(geom)).geom, null as originalid, l.ee, r.ee, adm0_a3_l, adm0_a3_r,
    'country'::vectiles.type_boundaries as type,
    case
        when 'EST' = any(array[adm0_a3_l, adm0_a3_r]) then 'country.domestic'
        else 'country.foreign'
    end::vectiles.subtype_boundaries as subtype,
    false as on_water
from
    vectiles_input.ne_10m_admin_0_boundary_lines_land lines
        left join trans l on
            l.en = lines.adm0_left
        left join trans r on
            r.en = lines.adm0_right
;
