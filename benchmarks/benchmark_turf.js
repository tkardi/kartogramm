/**
* Benchmarking Turfjs for unioning features.
* Details at https://github.com/tkardi/kahhelgramm/blob/master/benchmarks/README.md
*/
var walk = require('walk'),
	path = require('path'),
	fs = require('fs'),
	turf = require('turf'),
	reproject = require('reproject'),
	now = require('performance-now'),
	in_folder = process.argv[3],
	maxLoops = process.argv[2]
	index = JSON.parse(fs.readFileSync(path.join(in_folder, 'index.json')).toString()),
	crs = {'EPSG:3301':'+proj=lcc +lat_1=59.33333333333334 +lat_2=58 +lat_0=57.51755393055556 +lon_0=24 +x_0=500000 +y_0=6375000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'},
	featureCollection = {
		"type":"FeatureCollection",
		"crs":{"type":"name","properties":{"name":"urn:ogc:def:crs:OGC:1.3:CRS84"}},
		"features":[]
	},
	timeits = [];

function benchmarkProcessData(x, maxLoops) {
	var walker = walk.walk(in_folder, {}),
		feature_dump = {},
		start = now();
	walker
		.on("file", function(root, filestats, next) {
			if (['index.json', 'merged.json'].indexOf(filestats.name) == -1) {
				fs.readFile(path.join(in_folder, filestats.name), function (err, data) {
					var features = JSON.parse(data).features;
					features.map(function(feature) {
						var feature_id = feature.id,
							f = {
								id: feature_id,
								properties: feature.properties,
								geometry: reproject.toWgs84(feature.geometry, 'EPSG:3301', crs),
								"type": "Feature"
							};
						if (!feature_dump.hasOwnProperty(feature_id)) {
							feature_dump[feature_id] = [f];
						} else {
							feature_dump[feature_id].push(f);
						}
						var i = feature_dump[feature_id].length;
						if (i == index[feature_id].length) {
							var featureArray = feature_dump[feature_id],
								unioned = featureArray[0];
							if (i > 1) {
								for (var j=1; j<i; j++) {
									var nextFeature = featureArray[j];
									unioned = turf.union(unioned, nextFeature);
								}
							}
							/* we're done with this feature, so we can: */
							// featureCollection.features.push(unioned);
							/* and then clear it from the dump: */
							delete feature_dump[feature_id];
						}
					});
				})
			} 
			next();
		})
		.on("end", function() {
			var end = now();
			timeits.push(end-start);
			if (x  < maxLoops) {
				benchmarkProcessData(x + 1, maxLoops)
			} else {
				console.log('' + maxLoops + ' loops, best: ' + Math.min.apply(null, timeits) / 1000 + ' sec per loop');
			}
//			fs.writeFile(
//				path.join(in_folder, 'merged.json'), 
//				JSON.stringify(featureCollection), 
//				function(err) {
//					if (err) {
//						console.log(err);
//					}
//				}
//			);
		});
}

benchmarkProcessData(1, maxLoops);