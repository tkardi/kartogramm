try:
    from informal_district import tartu, tallinn
except ModuleNotFoundError as e:
    import tartu, tallinn

import argparse
import psycopg2

def prepare(**kwargs):
    with psycopg2.connect(**kwargs) as connection:
        with connection.cursor() as cursor:
            cursor.execute('truncate table vectiles_input.informal_district restart identity')
    tartu.prepare(**kwargs)
    tallinn.prepare(**kwargs)

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
