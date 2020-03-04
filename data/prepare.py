from ads import prepare as ads_prep
from etak import prepare as etak_prep
from informal_district import prepare as informal_district_prep
from k250 import prepare as k250_prep
from ne import prepare as ne_prep
from preprocessed import prepare as preprocessed_prep

import argparse
import psycopg2

def prepare(**kwargs):
    ads_prep.prepare(**kwargs)
    etak_prep.prepare(**kwargs)
    informal_district_prep.prepare(**kwargs)
    k250_prep.prepare(**kwargs)
    ne_prep.prepare(**kwargs)
    preprocessed_prep.prepare(**kwargs)

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
