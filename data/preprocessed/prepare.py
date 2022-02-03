import argparse
import requests
import io
import json
import os
import psycopg2

from datetime import datetime

FILES = [
    {'filename': 'bridges/bridges_for_rails', 'post_sql': 'insert into vectiles_input.bridges_for_rails (etak_id, for_rail, geom) select (properties->>\'etak_id\')::numeric::int as etak_id, (properties->>\'for_rail\')::boolean as for_rail, st_force2d(st_transform(st_setsrid(st_geomfromgeojson(geometry::text), 4326), 3301)) as geom from (select datas#>\'{properties}\' as properties, datas#>\'{geometry}\' as geometry from data_upload) f'},
    {'url':'https://tkardi.ee/kartogramm/data/admin/baltic_a0_expanded.json', 'filename': 'admin/baltic_a0_expanded', 'post_sql': 'insert into vectiles_input.baltic_a0_expanded (left_name, right_name, left_country_code, right_country_code, on_water, geom) select (properties->>\'left_name\')::varchar as left_name, (properties->>\'right_name\')::varchar as right_name, (properties->>\'left_country_code\')::varchar as left_country_code, (properties->>\'right_country_code\')::varchar as right_country_code, (properties->>\'on_water\')::boolean as on_water, st_force2d(st_transform(st_setsrid(st_geomfromgeojson(geometry::text), 4326), 3301)) as geom from (select datas#>\'{properties}\' as properties, datas#>\'{geometry}\' as geometry from data_upload) f'},
    {'url':'https://tkardi.ee/kartogramm/data/admin/baltic_admin.json', 'filename': 'admin/baltic_admin', 'post_sql': 'insert into vectiles_input.baltic_admin (hash, left_country_code, right_country_code, left_a1_code, left_a2_code, left_a3_code, left_a1, left_a2, left_a3, right_a1_code, right_a2_code, right_a3_code, right_a1, right_a2, right_a3, geom) select (properties->>\'hash\')::varchar as hash, (properties->>\'left_country_code\')::varchar as left_country_code, (properties->>\'right_country_code\')::varchar as right_country_code, (properties->>\'left_a1_code\')::varchar as left_a1_code, (properties->>\'left_a2_code\')::varchar as left_a2_code, (properties->>\'left_a3_code\')::varchar as left_a3_code, (properties->>\'left_a1\')::varchar as left_a1, (properties->>\'left_a2\')::varchar as left_a2, (properties->>\'left_a3\')::varchar as left_a3, (properties->>\'right_a1_code\')::varchar as right_a1_code, (properties->>\'right_a2_code\')::varchar as right_a2_code, (properties->>\'right_a3_code\')::varchar as right_a3_code, (properties->>\'right_a1\')::varchar as right_a1, (properties->>\'right_a2\')::varchar as right_a2, (properties->>\'right_a3\')::varchar as right_a3, st_force2d(st_transform(st_setsrid(st_geomfromgeojson(geometry::text), 4326), 3301)) as geom from (select datas#>\'{properties}\' as properties, datas#>\'{geometry}\' as geometry from data_upload) f'},
    {'url':'https://tkardi.ee/kartogramm/data/oceans/oceans.json', 'filename': 'oceans/oceans', 'post_sql': 'insert into vectiles_input.oceans (geom) select st_setsrid(st_geomfromgeojson(geometry::text), 4326) as geom from (select datas#>\'{geometry}\' as geometry from data_upload) f'},
    {'url':'https://tkardi.ee/kartogramm/data/lv/lv_waterways.json', 'filename': 'lv/lv_waterways', 'post_sql': 'insert into vectiles_input.lv_waterways (osm_id, code, fclass, width, name, geom) select (properties->>\'osm_id\')::bigint as osm_id, (properties->>\'code\')::int as code, (properties->>\'fclass\')::varchar as fclass, (properties->>\'width\')::int as width, (properties->>\'name\')::varchar as name, st_force2d(st_setsrid(st_geomfromgeojson(geometry::text), 4326)) as geom from (select datas#>\'{geometry}\' as geometry, datas#>\'{properties}\' as properties from data_upload) f'},
    {'url':'https://tkardi.ee/kartogramm/data/lv/lv_water.json', 'filename': 'lv/lv_water', 'post_sql': 'insert into vectiles_input.lv_water (osm_id, code, fclass, name, geom) select (properties->>\'osm_id\')::bigint as osm_id, (properties->>\'code\')::int as code, (properties->>\'fclass\')::varchar as fclass, (properties->>\'name\')::varchar as name, st_force2d(st_setsrid(st_geomfromgeojson(geometry::text), 4326)) as geom from (select datas#>\'{geometry}\' as geometry, datas#>\'{properties}\' as properties from data_upload) f'},
    {'url':'https://tkardi.ee/kartogramm/data/lv/lv_landuse.json', 'filename': 'lv/lv_landuse', 'post_sql': 'insert into vectiles_input.lv_landuse (osm_id, code, fclass, name, geom) select (properties->>\'osm_id\')::bigint as osm_id, (properties->>\'code\')::int as code, (properties->>\'fclass\')::varchar as fclass, (properties->>\'name\')::varchar as name, st_force2d(st_setsrid(st_geomfromgeojson(geometry::text), 4326)) as geom from (select datas#>\'{geometry}\' as geometry, datas#>\'{properties}\' as properties from data_upload) f'},
    {'url':'https://tkardi.ee/kartogramm/data/lv/lv_roads.json', 'filename': 'lv/lv_roads', 'post_sql': 'insert into vectiles_input.lv_roads (osm_id, code, fclass, name, ref, oneway, bridge, tunnel, geom) select (properties->>\'osm_id\')::bigint as osm_id, (properties->>\'code\')::int as code, (properties->>\'fclass\')::varchar as fclass, (properties->>\'name\')::varchar as name, (properties->>\'ref\')::varchar as ref, (properties->>\'oneway\')::varchar as oneway, (properties->>\'bridge\')::varchar as bridge, (properties->>\'tunnel\')::varchar as tunnel, st_force2d(st_setsrid(st_geomfromgeojson(geometry::text), 4326)) as geom from (select datas#>\'{geometry}\' as geometry, datas#>\'{properties}\' as properties from data_upload) f'},
    {'url':'https://tkardi.ee/kartogramm/data/lv/lv_railways.json', 'filename': 'lv/lv_railways', 'post_sql': 'insert into vectiles_input.lv_railways (category, disp_scale, geom) select (properties->>\'category\')::int as category, (properties->>\'disp_scale\')::varchar as disp_scale, st_force2d(st_setsrid(st_geomfromgeojson(geometry::text), 4326)) as geom from (select datas#>\'{geometry}\' as geometry, datas#>\'{properties}\' as properties from data_upload) f'},

]

def _get_iterator(r):
    if hasattr(r, 'iter_lines'):
        return r.iter_lines()
    return r

def get_data(f, *args, **kwargs):
    with f(*args, **kwargs) as r:
        lines = []
        for cnt, line in enumerate(_get_iterator(r)):
            if line == b'' or line == '\n':
                continue
            if not isinstance(line, str) and not line.endswith(b'\n'):
                line = line.decode('utf-8').replace('\"', '\\"')
                line += '\n'

            lines.append(line)

            if cnt > 0 and cnt % 50 == 0:
                yield io.StringIO(''.join(lines).rstrip('\n'))
                lines = []
        if len(lines) > 0:
            yield io.StringIO(''.join(lines).rstrip('\n'))


def prepare(**kwargs):
    for file in FILES:
        url = file.get('url')
        filename = file['filename']
        tabname = filename.split('/')[-1]
        p = os.path.dirname(os.path.abspath(__file__))
        fp = os.path.join(p, '%s.json' % filename)
        if url:
            f = requests.get
            args = (url,)
            params = {'stream':True}
        else:
            f = open
            args = (fp, 'r')
            params = {}
        print ('%s Import %s using %s, args=%s, kwargs=%s' % (datetime.now(), filename, f, args, params))
        with psycopg2.connect(**kwargs) as connection:
            with connection.cursor() as cursor:
                cursor.execute('create temp table data_upload(datas json)')
                for buffer in get_data(f, *args, **params):
                    cursor.copy_from(buffer, 'data_upload')
                cursor.execute('truncate table vectiles_input.%s restart identity' % tabname )
                print ('%s Postpreparing with: "%s"' % (datetime.now(), file['post_sql']))
                cursor.execute(file['post_sql'])
                print('%s Done postprepare for vectiles_input.%s' % (datetime.now(), tabname))
        print ('%s Done with %s.' % (datetime.now(), filename))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '-H', '--host',
        help='Specify db server host name defaults to `localhost`.',
        default='localhost'
    )
    parser.add_argument(
        '-D', '--dbname',
        help='Specify db name defaults to `postgres`.',
        default='postgres'
    )
    parser.add_argument(
        '-U', '--user',
        help='Specify db username, defaults to `postgres`.',
        default='postgres'
    )

    args = parser.parse_args()
    prepare(**vars(args))
