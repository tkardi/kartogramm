import argparse
import requests
import io
import os
import psycopg2

from datetime import datetime

FILES = [
    {'filename': 'bridges/bridges_for_rails', 'post_sql': 'insert into vectiles_input.bridges_for_rails (etak_id, for_rail, geom) select (properties->>\'etak_id\')::numeric::int as etak_id, (properties->>\'for_rail\')::boolean as for_rail, st_force2d(st_transform(st_setsrid(st_geomfromgeojson(geometry::text), 4326), 3301)) as geom from (select datas#>\'{properties}\' as properties, datas#>\'{geometry}\' as geometry from data_upload) f'},
    {'filename': 'bridges/bridges_for_roads', 'post_sql': 'insert into vectiles_input.bridges_for_roads (etak_id, for_road, geom) select (properties->>\'etak_id\')::numeric::int as etak_id, (properties->>\'for_road\')::boolean as for_road, st_force2d(st_transform(st_setsrid(st_geomfromgeojson(geometry::text), 4326), 3301)) as geom from (select datas#>\'{properties}\' as properties, datas#>\'{geometry}\' as geometry from data_upload) f'},
]

def get_data(fp):
    with open(fp) as r:
        lines = []
        for cnt, line in enumerate(r):
            lines.append(line)
            if cnt > 0 and cnt % 50 == 0:
                yield io.StringIO(''.join(lines))
                lines = []
        if len(lines) > 0:
            yield io.StringIO(''.join(lines))


def prepare(**kwargs):
    for file in FILES:
        filename = file['filename']
        tabname = filename.split('/')[-1]
        p = os.path.dirname(os.path.abspath(__file__))
        fp = os.path.join(p, '%s.json' % filename)
        print ('%s Import %s.' % (datetime.now(), fp))
        with psycopg2.connect(**kwargs) as connection:
            with connection.cursor() as cursor:
                cursor.execute('create temp table data_upload(datas json)')
                for buffer in get_data(fp):
                    cursor.copy_from(buffer, 'data_upload')
                cursor.execute('truncate table vectiles_input.%s restart identity' % tabname )
                print ('%s Postpreparing with: "%s"' % (datetime.now(), file['post_sql']))
                cursor.execute(file['post_sql'])
                print('%s Done postprepare for vectiles_input.%s' % (datetime.now(), tabname))
        print ('%s Done with %s.' % (datetime.now(), fp))


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
