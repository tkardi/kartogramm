import argparse
import psycopg2
import os

from datetime import datetime

TABLES = [
    '0000.init.bridges',
    '0000.init.tunnels',
    '0010.prep.roads',
    '0011.prep.railways',
    'waterline', 'water',
    'natural', 'agricultural',
    'builtup', 'infrastructure',
    'railways', 'roads',
    'boundaries', 'labels'
]

ZOOMS = [
    'low',
    'med',
    'high'
]

def _strip_line_comments(sql_line):
    if sql_line.startswith('/*') or sql_line.endswith('*/'):
        return sql_line
    return sql_line.split('--')[0].strip()

def get_sql(zooms, table):
    assert zooms in ['low', 'med', 'high'], 'zooms must be one of low, med, or high. Was "%s"' % zooms
    p = os.path.dirname(os.path.abspath(__file__))
    fp = os.path.join(p, zooms, '%s.sql' % table)
    if os.path.exists(fp):
        with open(fp) as f:
            sqls = f.read().split(';')
            for sql in sqls:
                lines = [_strip_line_comments(l.strip()) for l in sql.split('\n') if l.strip() != '']
                _sql = ' '.join([line for line in lines if line != ''])
                if _sql.strip() != '':
                    print ('%s |-TABLE: %s, sql from %s: %s' % (datetime.now(), table, fp, _sql))
                    yield _sql
    else:
        print ('%s |-TABLE: %s, sql not found at %s' % (datetime.now(), table, fp))

def prepare(**kwargs):
    z = kwargs.pop('zooms')
    tabs = kwargs.pop('tables')
    for zooms in ZOOMS:
        if zooms not in z:
            continue
        print ('%s ZOOMS: %s' % (datetime.now(), zooms))
        for table in TABLES:
            if table not in tabs:
                continue
            print ('%s |-TABLE: %s' % (datetime.now(), table))
            with psycopg2.connect(**kwargs) as connection:
                with connection.cursor() as cursor:
                    [cursor.execute(sql) for sql in get_sql(zooms, table) if sql != None]

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
    parser.add_argument(
        '-Z', '--zooms',
        help='Specify zooms (`low`,`med`, and/or `high`) to postprocess. Defaults to all. For multiple selection space-delimit the values e.g. `-Z low med`',
        default=ZOOMS,
        nargs='*'
    )
    parser.add_argument(
        '-T', '--tables',
        help='Specify tables (`water`,`waterline`, `natural`, etc.) to postprocess. Defaults to all. For multiple selection space-delimit the values, e.g. `-T water builtup roads`',
        default=TABLES,
        nargs='*'
    )

    args = parser.parse_args()
    prepare(**vars(args))
