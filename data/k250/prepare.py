import argparse
import requests
import zipfile
import io
import os
import subprocess
import tempfile

from datetime import datetime

URL = 'https://geoportaal.maaamet.ee/docs/Avaandmed/Topo250T_Maaamet_SHP.zip'
FILES = [
    {'filename': 'Kolvik', 'params': '-S'},
    {'filename': 'Kohanimi', 'params': '-S'},
    {'filename': 'Piir', 'params': '-S'},
    {'filename': 'Roobastee', 'params': '-S'},
    {'filename': 'Tee', 'params': '-S'},
    {'filename': 'Vooluvesi'}
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
            kw['tabname'] = 'k250_%s' % file['filename'].lower()
            if 'params' not in kw:
                kw['params'] = ''
            kw.update(kwargs)
            cmd = 'shp2pgsql -d -s 3301 -g geom -W "cp1257" -I  %(params)s %(filename)s vectiles_input.%(tabname)s | psql -h %(hostname)s -d %(dbname)s -U %(username)s --quiet' % kw
            print ('%s Importing %s to vectiles_input.%s' % (datetime.now(), kw['filename'], kw['tabname']))
            subprocess.call(cmd, shell=True)
            print('%s Done' % datetime.now())


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '-H', '--hostname',
        help='Specify db server host name defaults to `localhost`.',
        default='localhost'
    )
    parser.add_argument(
        '-D', '--dbname',
        help='Specify db name defaults to `postgres`.',
        default='postgres'
    )
    parser.add_argument(
        '-U', '--username',
        help='Specify db username, defaults to `postgres`.',
        default='postgres'
    )

    args = parser.parse_args()
    prepare(**vars(args))
