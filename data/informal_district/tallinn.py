import argparse
import requests
import zipfile
import io
import os
import subprocess
import tempfile
import psycopg2

from datetime import datetime

URL = 'http://www.tallinn.ee/est/g6497s92804'
FILES = [
    {'filename': 't02_41_asum', 'post_sql': 'insert into vectiles_input.informal_district (name, geom) select asumi_nimi, (st_dump(geom)).geom as geom from vectiles_input.t02_41_asum'}
]

def get_data(to_path):
    print('%s Saving %s to %s' % (datetime.now(), URL, to_path))
    r = requests.get(URL, stream=True)
    r.raise_for_status()
    z = zipfile.ZipFile(io.BytesIO(r.content))
    z.extractall(to_path)

def prepare(**kwargs):
    with tempfile.TemporaryDirectory() as wd:
        get_data(wd)
        for file in FILES:
            kw = file.copy()
            kw['filename'] = os.path.join(wd, '%s.shp' % file['filename'])
            kw['tabname'] = file['filename'].lower()
            if 'params' not in kw:
                kw['params'] = ''
            kw.update(kwargs)
            cmd = 'shp2pgsql -d -s 3301 -g geom -W "UTF-8" -I  %(params)s %(filename)s vectiles_input.%(tabname)s | psql -h %(host)s -d %(dbname)s -U %(user)s --quiet' % kw
            print ('%s Importing %s to vectiles_input.%s' % (datetime.now(), kw['filename'], kw['tabname']))
            subprocess.call(cmd, shell=True)
            print('%s Done file import.' % datetime.now())
            postprepare(file.get('post_sql'), **kwargs)

def postprepare(sql, **kwargs):
    if sql:
        print ('%s Running postprepare with %s' % (datetime.now(), sql))
        with psycopg2.connect(**kwargs) as connection:
            with connection.cursor() as cursor:
                cursor.execute(sql)
            print ('%s Done postprepare.' % (datetime.now(), ))
