import json
import os

from flask import Flask, request, send_file, make_response
from flask import Response
from flask import jsonify
from flask_compress import Compress

from tile import TileRequestHandler
from tile import ToHTTPError

app = Flask(__name__, static_url_path=os.path.dirname(os.path.join(os.path.abspath(__file__), 'static')))
Compress(app)

app.config['COMPRESS_MIMETYPES'].append('application/vnd.mapbox-vector-tile')

@app.errorhandler(ToHTTPError)
def handle_tohttperror(error):
    response = jsonify(error.to_dict())
    response.status_code = error.status_code
    response.headers = {'Access-Control-Allow-Origin':'*'}
    return response

@app.route("/")
def root():
    return send_file(os.path.join('static', 'index.html'))

@app.route("/<int:z>/<int:x>/<int:y>/")
def tile(z, x, y):
    return Response(
        TileRequestHandler(z, x, y).serve_tile(),
        mimetype='application/vnd.mapbox-vector-tile',
        headers={'Access-Control-Allow-Origin':'*'}
    )

@app.route("/glyphs/<string:fontstack>/<string:range>/")
def glyphs(fontstack, range):
    response = make_response(send_file(os.path.join('static', fontstack, '%s.pbf' % range)))
    response.mimetype='application/vnd.mapbox-vector-tile'
    response.headers={'Access-Control-Allow-Origin':'*'}
    return response


if __name__ == '__main__':
    app.run()
