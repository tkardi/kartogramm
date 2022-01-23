import argparse
import requests
import zipfile
import io
import os
import subprocess
import tempfile

from datetime import datetime

URL = 'https://naciscdn.org/naturalearth/10m/cultural/10m_cultural.zip'
FILES = [
    {'filename': 'ne_10m_urban_areas', 'params': '-S'},
    {'filename': 'ne_10m_railroads', 'params': '-S'},
    {'filename': 'ne_10m_admin_0_boundary_lines_land'},
    {'filename': 'ne_10m_populated_places', 'params': '-S'},
    {'filename': 'ne_10m_admin_0_countries'},

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
            kw['filename'] = os.path.join(wd, '10m_cultural', '%s.shp' % file['filename'])
            kw['tabname'] = '%s' % file['filename'].lower()
            if 'params' not in kw:
                kw['params'] = ''
            kw.update(kwargs)
            cmd = 'shp2pgsql -d -s 4326 -g geom -W "utf-8" -I  %(params)s %(filename)s vectiles_input.%(tabname)s | psql -h %(host)s -d %(dbname)s -U %(user)s --quiet' % kw
            print ('%s Importing %s to vectiles_input.%s' % (datetime.now(), kw['filename'], kw['tabname']))
            subprocess.call(cmd, shell=True)
            print('%s Done' % datetime.now())


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
