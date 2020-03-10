import psycopg2
import json

import concurrent.futures

# 2020.03.10 @tkardi: credit where credit is due! largely based on
# Paul Ramsey's minimal-mvt (for educational purposes) from
# https://github.com/pramsey/minimal-mvt with some modifications to run
# with Flask and multiple layers in the same tile. This ought to be
# a quick way to check the data that's gone into the database and diff
# ways to pull it out as mvt.

# UNDER NO CIRCUMSTANCES SHOULD THIS BE USED TO ACTUALLY SERVE TILES FOR REALS.
# Use a real vector tile server for that.

with open('conf.json') as f:
    d = json.loads(f.read())
    CONF = d['layers']
    DATABASE = d['database']
    TIMEOUT = d['timeout']


class ToHTTPError(Exception):
    status_code = 500

    def __init__(self, message, status_code=None, payload=None):
        Exception.__init__(self)
        self.message = message
        if status_code is not None:
            self.status_code = status_code
        self.payload = payload

    def to_dict(self):
        rv = dict(self.payload or ())
        rv['message'] = self.message
        return rv


class TileRequestHandler(object):
    DATABASE_CONNECTION = None
    def __init__(self, z, x, y, log_file=None, format='pbf'):
        self.tile = dict(
            x=x,
            y=y,
            zoom=z,
            format=format
        )

    # Do we have all keys we need?
    # Do the tile x/y coordinates make sense at this zoom level?
    def tileIsValid(self, tile):
        if not ('x' in tile and 'y' in tile and 'zoom' in tile):
            return False
        if 'format' not in tile or tile['format'] not in ['pbf', 'mvt']:
            return False
        size = 2 ** tile['zoom'];
        if tile['x'] >= size or tile['y'] >= size:
            return False
        if tile['x'] < 0 or tile['y'] < 0:
            return False
        return True

    # Calculate envelope in "Spherical Mercator" (https://epsg.io/3857)
    def tileToEnvelope(self, tile):
        # Width of world in EPSG:3857
        worldMercMax = 20037508.3427892
        worldMercMin = -1 * worldMercMax
        worldMercSize = worldMercMax - worldMercMin
        # Width in tiles
        worldTileSize = 2 ** tile['zoom']
        # Tile width in EPSG:3857
        tileMercSize = worldMercSize / worldTileSize
        # Calculate geographic bounds from tile coordinates
        # XYZ tile coordinates are in "image space" so origin is
        # top-left, not bottom right
        env = dict()
        env['xmin'] = worldMercMin + tileMercSize * tile['x']
        env['xmax'] = worldMercMin + tileMercSize * (tile['x'] + 1)
        env['ymin'] = worldMercMax - tileMercSize * (tile['y'] + 1)
        env['ymax'] = worldMercMax - tileMercSize * (tile['y'])
        tile['pixel_width'] = (env['xmax'] - env['xmin']) / 256
        tile['pixel_height'] = (env['ymax'] - env['ymin']) / 256
        return env

    # Generate SQL to materialize a query envelope in EPSG:3857.
    # Densify the edges a little so the envelope can be
    # safely converted to other coordinate systems.
    def envelopeToBoundsSQL(self, env):
        DENSIFY_FACTOR = 4
        env['segSize'] = (env['xmax'] - env['xmin'])/DENSIFY_FACTOR
        sql_tmpl = 'ST_Segmentize(ST_MakeEnvelope({xmin}, {ymin}, {xmax}, {ymax}, 3857),{segSize})'
        return sql_tmpl.format(**env)

    # Generate a SQL query to pull a tile worth of MVT data
    # from the table of interest.
    def envelopeToSQL(self, env, table):
        tbl = table.copy()
        tbl['env'] = self.envelopeToBoundsSQL(env)
        # Materialize the bounds
        # Select the relevant geometry and clip to MVT bounds
        # Convert to MVT format
        sql_tmpl = """
            with
            bounds AS (
                select
                    {env} as geom,
                    {env}::box2d as b2d
            ),
            mvtdata as (
                select
                    st_asmvtgeom(f.geom, bounds.b2d) as geom,
                    {attrColumns}
                from (
                    select (st_dump(st_union(f.geom))).geom as geom, {attrColumns}
                    from (
                        select
                            (st_dump(
                                case
                                    when {simplify}=true and lower(geometrytype(t.{geomColumn})) = 'linestring' then st_simplify(st_transform(t.{geomColumn}, 3857), {simplify_factor})
                                    when {simplify}=true and lower(geometrytype(t.{geomColumn})) = 'polygon' then st_makevalid(st_simplifypreservetopology(st_makevalid(st_snaptogrid(st_transform(t.{geomColumn}, 3857), {simplify_factor})), {simplify_factor} / 5))
                                    else st_transform(t.{geomColumn}, 3857)
                                end
                            )).geom as geom,
                            {attrColumns}
                        from
                            {table} t, bounds
                        where
                            st_intersects(t.{geomColumn}, st_transform(bounds.geom, {srid})) and {condition}
                    ) f, bounds
                    where lower(geometrytype(f.geom)) = lower('{geometrytype}')
                    group by {attrColumns}
                ) f, bounds
            )
            select st_asmvt(mvtdata.*,'{name}', 4096, 'geom') from mvtdata
        """
        return sql_tmpl.format(**tbl)

    def debug(self, env, tile):
        _tile = tile.copy()
        _tile['env'] = self.envelopeToBoundsSQL(env)
        print ('ENV: ', env)
        sql_tmpl = """
            with
            bounds AS (
                select
                    {env} as geom,
                    {env}::box2d as b2d
            ),
            b as (
                select
                    st_asmvtgeom(bounds.geom, bounds.b2d) as geom,
                    {x} as x, {y} as y, {zoom} as z, 'bounds' as name
                from
                    bounds
            ),
            c as (
                select
                    st_asmvtgeom(st_centroid(bounds.geom), bounds.b2d) as geom,
                    {x} as x, {y} as y, {zoom} as z, 'bounds_centroid' as name
                from bounds
            )
            select st_asmvt(c.*, c.name , 4096, 'geom')||st_asmvt(b.*, b.name , 4096, 'geom') from c, b where 1= 1
        """
        #print('TILE:', sql_tmpl.format(**_tile))
        return sql_tmpl.format(**_tile)

    # Run tile query SQL and return error on failure conditions
    def sqlToPbf(self, sql):
        if not self.DATABASE_CONNECTION or self.DATABASE_CONNECTION.closed == 1:
            try:
                self.DATABASE_CONNECTION = psycopg2.connect(**DATABASE)
            except (Exception, psycopg2.Error) as error:
                raise ToHTTPError(
                    message="cannot connect: %s" % (str(DATABASE), ),
                    status_code=500
                )
        # Query for MVT
        with self.DATABASE_CONNECTION.cursor() as cur:
            cur.execute(sql)
            if not cur:
                raise ToHTTPError(
                    message="SQL query failed: %s" % sql,
                    status_code=404
                )
            return b''.join([row[0] for row in cur.fetchall()])

    def get_tile_data(self, env, table, debug):
        sql = self.envelopeToSQL(env, table)
        if debug == True:
            print("TILE: %s\nSQL: %s" % (self.tile, sql))
        pbf = self.sqlToPbf(sql)
        return pbf

    def zoomToTables(self, tile, debug=True):
        for table in CONF:
            if table.get('minZoom', 0) <= tile['zoom'] <= table.get('maxZoom', 25):
                _table = table.copy()
                _table['condition'] = table.get('condition', '1=1').format(**tile)
                _table['pixel_width'] = tile['pixel_width']
                _table['pixel_height'] = tile['pixel_height']
                if tile['pixel_width'] > 1:
                    _table['simplify'] = table.get('simplify', 'false')
                    _table['simplify_factor'] = round(tile['pixel_width'], -1) / 4
                else:
                    _table['simplify'] = 'false'
                    _table['simplify_factor'] = 1
                yield _table

    def serve_tile(self, debug=True):
        if not (self.tile and self.tileIsValid(self.tile)):
            raise ToHTTPError(
                message="invalid tile path: /%(zoom)s/%(x)s/%(y)s/" % self.tile,
                status_code=400
            )

        env = self.tileToEnvelope(self.tile)

        try:
            pbf = b''.join([self.get_tile_data(env, table, debug) for table in self.zoomToTables(self.tile)])

            if debug == True:
                sql = self.debug(env, self.tile)
                pbf += self.sqlToPbf(sql)
            return pbf

        except ToHTTPError:
            raise

        except Exception as e:
            raise ToHTTPError(
                message=str(e),
                status_code=500
            )

        # pbfs = []
        # try:
        #     with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        #         tasks = {executor.submit(self.get_tile_data, env, table): table for table in self.zoomToTables(self.tile)}
        #
        #         for task in concurrent.futures.as_completed(tasks, timeout=TIMEOUT):
        #             if task.exception() is not None:
        #                 raise task.exception()
        #             else:
        #                 data = task.result()
        #                 pbfs.append(data)
        #
        # except ToHTTPError:
        #     raise
        #
        # except concurrent.futures.TimeoutError:
        #     raise ToHTTPError(
        #         message='Timeout',
        #         status_code=500
        #     )
        # except Exception as e:
        #     raise ToHTTPError(
        #         message=str(e),
        #         status_code=500
        #     )
        #
        # return b''.join(pbfs)
