Although called Baltic these layers currently contain only Estonian and Latvian
borders.

## baltic_a0_expanded

For EE contains data from [Estonian Land Board](https://maaamet.ee)'s 1:250K
[Generalized Estonian Topographic data](https://geoportaal.maaamet.ee/index.php?lang_id=2&page_id=554)
used under _Maa-ameti avatud ruumiandmete litsents, 01.09.2016_
(verbatim copy of the license incl. in the zip file).

This has bee merged with LV _expanded border_ which has been created
by applying a 10 nautical mile buffer to the LV Baltic Sea coastline from
1:1.2M generalized Latvian administrative division (as of January 2018) by
[Statistics Latvia](https://www.csb.gov.lv/en/sakums) via
[Latvia Open Data Portal](https://data.gov.lv) via
[Open Data Portal Watch](https://data.wu.ac.at/schema/data_gov_lv/ZTNkNjA2ZjItNmQzOC00NDRkLWI3NjctMTE5ZmRjYzQzNWZl)
used under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

This layer is downloadable from
[https://tkardi.ee/kartogramm/data/admin/baltic_a0_expanded.json](https://tkardi.ee/kartogramm/data/admin/baltic_a0_expanded.json)
and shared under [CC-BY-SA](https://creativecommons.org/licenses/by-sa/4.0/)


## baltic_admin

The `baltic_admin` layer has bee created by fusing merging of
[Estonian administrative division](https://geoportaal.maaamet.ee/eng/Spatial-Data/Administrative-and-Settlement-Division-p312.html)
(EHAK) by [Estonian Land Board](https://www.maaamet.ee/en) under
[Land Board Open Data License](https://geoportaal.maaamet.ee/docs/Avaandmed/Licence-of-open-data-of-Estonian-Land-Board.pdf)
with 1:1.2M generalized Latvian administrative division (as of January 2018) by
[Statistics Latvia](https://www.csb.gov.lv/en/sakums) via
[Latvia Open Data Portal](https://data.gov.lv) via
[Open Data Portal Watch](https://data.wu.ac.at/schema/data_gov_lv/ZTNkNjA2ZjItNmQzOC00NDRkLWI3NjctMTE5ZmRjYzQzNWZl)
used under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). As the
LV units are generalized then EE/LV overlapping unit parts have been removed
from LV units (`ST_Difference`) and gaps between the two countries have been
filled and added to the LV units. `v.clean` using GRASS and then converted to
lines using a little utility available at
[tkardi/mesher](https://github.com/tkardi/mesher/)

This layer is downloadable from
[https://tkardi.ee/kartogramm/data/admin/baltic_admin.json](https://tkardi.ee/kartogramm/data/admin/baltic_admin.json)
and shared under [CC-BY-SA](https://creativecommons.org/licenses/by-sa/4.0/)
