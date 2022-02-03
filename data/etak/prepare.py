import argparse
import requests
import zipfile
import io
import os
import subprocess
import tempfile

from datetime import datetime

URL = 'https://geoportaal.maaamet.ee/index.php?lang_id=1&plugin_act=otsing&andmetyyp=ETAK&dl=1&f=ETAK_EESTI_SHP.zip&page_id=609'
FILES = [
    {'filename': 'E_202_seisuveekogu_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_203_vooluveekogu_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_203_vooluveekogu_j', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_301_muu_kolvik_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_302_ou_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_303_haritav_maa_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_304_lage_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_305_puittaimestik_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_306_margala_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_306_margala_ka', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_307_turbavali_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_401_hoone_ka', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_403_muu_rajatis_ka', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_404_maaalune_hoone_ka', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_501_tee_a', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_502_roobastee_j', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_503_siht_j', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_505_liikluskorralduslik_rajatis_ka', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_505_liikluskorralduslik_rajatis_j', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_301_muu_kolvik_ka', 'params': '-S -W "LATIN1"'},
    {'filename': 'E_501_tee_j', 'params': '-S -W "LATIN1"'},
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
            kw['tabname'] = '%s' % file['filename'].lower()
            if 'params' not in kw:
                kw['params'] = ''
            kw.update(kwargs)
            cmd = 'shp2pgsql -d -s 3301 -g geom -I %(params)s %(filename)s vectiles_input.%(tabname)s | psql -h %(host)s -d %(dbname)s -U %(user)s --quiet' % kw
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
