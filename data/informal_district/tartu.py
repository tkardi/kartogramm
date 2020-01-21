import requests
import io
import json
import os
import tempfile
import psycopg2

from datetime import datetime

FILES = [
    {'filename': 'informal_district', 'url': 'https://gis.tartulv.ee/arcgis/rest/services/Planeeringud/GI_linnaosad/MapServer/0/query?where=1%3D1&outfields=objectid,nimi&outSR=4326&f=geojson'}
]

def get_data(**kwargs):
    url = kwargs['url']
    print('%s Getting %s' % (datetime.now(), url))
    r = requests.get(url)
    r.raise_for_status()
    return io.StringIO(r.text)


def prepare(**kwargs):
    for file in FILES:
        buffer = get_data(**file)
        with psycopg2.connect(**kwargs) as connection:
            with connection.cursor() as cursor:
                cursor.execute('create temp table data_upload(datas json)')
                cursor.copy_from(buffer, 'data_upload')
                sql = """
                insert into vectiles_input.informal_district (
                    name, geom
                )
                select
                    (properties->>'NIMI')::varchar as name,
                    st_transform(st_setsrid(st_geomfromgeojson(geometry), 4326), 3301) as geom
                from
                    json_to_recordset(
                        (select datas#>'{features}' as features from data_upload)
                    ) as x(properties json, geometry text)
                """.replace('\n', '')
                print ('%s Importing %s to vectiles_input.%s' % (datetime.now(), file['url'], file['filename']))
                cursor.execute(sql)
        print ('%s Done.' % (datetime.now(), ))
