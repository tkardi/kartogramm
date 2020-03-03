import argparse
import io
import os
import psycopg2
import requests
import subprocess
import tempfile
import zipfile

from datetime import datetime

META_URL = 'https://xgis.maaamet.ee/adsavalik/valjav6te'

def get_csv_download_url():
    r = requests.get(META_URL)
    r.raise_for_status()
    for x in r.json():
        if x['vvnr'] == 1 and not 'kov' in x:
            return x['fail']

def get_data(to_path, url):
    print('%s Saving %s to %s' % (datetime.now(), url, to_path))
    r = requests.get(url, stream=True)
    r.raise_for_status()
    z = zipfile.ZipFile(io.BytesIO(r.content))
    z.extractall(to_path)
    return z.namelist()[0]


def prepare(**kwargs):
    csvzip = get_csv_download_url()
    print('%s Extract zipname %s ' % (datetime.now(), csvzip))

    with tempfile.TemporaryDirectory() as wd:
        url = '%s/%s' % (META_URL, csvzip)
        filename = get_data(wd, url)
        kw = dict(
            filename=filename,
            fp=os.path.join(wd, filename),
            tabname='ee_address_object'
        )
        kw.update(kwargs)
        with psycopg2.connect(**kwargs) as connection:
            with connection.cursor() as cursor:
                cursor.execute('truncate table vectiles_input.ee_address_object restart identity')

        cmd = 'psql -h %(host)s -d %(dbname)s -U %(user)s -c "\\copy vectiles_input.%(tabname)s (adob_id,ads_oid,adob_liik,orig_tunnus,etak_id,ads_kehtiv,un_tunnus,hoone_oid,adr_id,koodaadress,taisaadress,lahiaadress,aadr_olek,viitepunkt_x,viitepunkt_y,tase1_kood,tase1_nimetus,tase1_nimetus_liigiga,tase2_kood,tase2_nimetus,tase2_nimetus_liigiga,tase3_kood,tase3_nimetus,tase3_nimetus_liigiga,tase4_kood,tase4_nimetus,tase4_nimetus_liigiga,tase5_kood,tase5_nimetus,tase5_nimetus_liigiga,tase6_kood,tase6_nimetus,tase6_nimetus_liigiga,tase7_kood,tase7_nimetus,tase7_nimetus_liigiga,tase8_kood,tase8_nimetus,tase8_nimetus_liigiga) FROM \'%(fp)s\' delimiter \';\' null \'\' csv header encoding \'WIN1257\'"' % kw

        print ('%s Importing %s to vectiles_input.%s' % (datetime.now(), kw['fp'], kw['tabname']))
        subprocess.call(cmd, shell=True)
        print('%s Done' % datetime.now())
        with psycopg2.connect(**kwargs) as connection:
            with connection.cursor() as cursor:
                cursor.execute('update vectiles_input.ee_address_object set geom = st_setsrid(st_point(viitepunkt_x, viitepunkt_y), 3301)')
        print('%s Done geom update' % datetime.now())


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
