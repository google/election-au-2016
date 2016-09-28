# Australian Election 2016 Application
See LICENSE for usage and distribution restrictions.

## Summary

In 2016 there was a national election in Australia, this application was used to
show the current state of the nation, where it was possible to vote, and once
voting had closed the live results as they came in.

It consists of three main components:

1. A dart-based client (under `dart_frontend`). This is an Angular2 application
   which uses a simple read-only HTTP API to get geospatial data combined with
   Firebase to have real-time data and application state.

2. A go-based server (under `go_backend`). This was responsible for serving the
   static geospatial data, as well as the physical locations of polling places.
   It was also capable of computing the electorate for a given location.

3. [Not Included]: A utility that read various data sources (predominantly the
   AEC) for the state of the election and pushed this data to Firebase. It is
   possible to understand the Firebase schema readily from the running website
   or from the `firebase_service`.

The live version of this website is visible at: https://ausvotes.withgoogle.com

## Dependencies

You'll need:

* [Docker](https://www.docker.com/) - without need for sudo-prefix.
* [Go](https://golang.org/) - ensure GOPATH is set.
* [Dart](https://www.dartlang.org/)
* Make
* If using Appengine [Go Appengine] (https://cloud.google.com/appengine/docs/go/)
* A Google Maps [API key] (https://developers.google.com/maps/documentation/javascript/get-api-key), for [this file] (./go_backend/election.go) and [that one] (./dart_frontend/web/index.html).

Please also ensure you comply with the various [licenses] (./LICENSE).

## Running the Application

### Running Locally - go backend

To run the go backend locally:

```bash
make
./serve
```

If all the dependencies are met, make will create the dataset, build the go application and the dart frontend.

Access the local server at http://localhost:8090/.

### Running Locally - Dart frontend

To run the frontend client against an existing backend:

```bash
make
cd dart_frontend
pub serve
```

Access the local server at http://localhost:8080/.

You can edit [dart_frontend/lib/conf/config_debug.yaml] (dart_frontend/lib/conf/config_debug.yaml) to modify `pub serve`'s backend.

### Deployment to Appengine

To deploy to appengine, ensure the cloned project is associated with an appengine project (normally done via https://console.cloud.google.com/code/develop).
Once that's done, you should be able run `make install`.

## Examples of the Raw API

The following REST requests show how the Go App Engine hosted API can be
used to make queries against the shape data that is used to show electorates
on the map.

### Which electorates are in this viewport?

Request:

```
/viewport/11?bbox=-12.73,130.83,-12.26,131.2
```

Response:

```json
{
   "type":"FeatureCollection",
   "features":[
      {
         "id":"electorate_ids",
         "type":"Feature",
         "geometry":null,
         "properties":{
            "electorates":[
               "lingiari",
               "solomon"
            ],
            "type":"electorate_ids"
         }
      },
      {
         "id":"solomon",
         "type":"Feature",
         "geometry":{
            "type":"MultiPoint",
            "coordinates":[
               [
                  130.94715881347656,
                  -12.411874771118164
               ]
            ]
         },
         "properties":{
            "name":"Solomon",
            "type":"electorate_label"
         }
      },
      {
         "id":"lingiari",
         "type":"Feature",
         "geometry":{
            "type":"MultiPoint",
            "coordinates":[
               [
                  133.43023681640625,
                  -19.41421890258789
               ],
               [
                  137.03176879882812,
                  -15.710556983947754
               ],
               [
                  136.58103942871094,
                  -14.002981185913086
               ],
               [
                  130.35406494140625,
                  -11.622258186340332
               ],
               [
                  131.0478973388672,
                  -11.589698791503906
               ]
            ]
         },
         "properties":{
            "name":"Lingiari",
            "type":"electorate_label"
         }
      }
   ]
}
```

### Fetch the geometry for electorates Lingiari and Solomon

_Note_: For readability, `allowEncodedPolylineFeatureCollection` in [go_backend/http.go] (go_backend/http.go) was set to false for generating this output.
The application otherwise sends an [encoded polyline](https://developers.google.com/maps/documentation/utilities/polylineutility) JSON response, to reduce payload size.
The client can work with either formats.

Request:

```
/electorates/6?ids=lingiari,solomon
```

Response (truncated):

```json
{
    "type": "FeatureCollection",
    "bbox": [
        96.816766,
        -25.999482,
        138.001198,
        -10.412356
    ],
    "features": [
        {
            "id": "lingiari",
            "type": "Feature",
            "bbox": [
                96.816766,
                -25.999482,
                138.001198,
                -10.412356
            ],
            "geometry": {
                "type": "MultiPolygon",
                "coordinates": [
                    [
                        [
                            [
                                136.034257,
                                -13.716478
                            ],
                            [
                                136.015038,
                                -13.830947
                            ],
                            ...
                            [
                                135.917549,
                                -13.977928
                            ]
                        ]
                    ],
                    [
                        [
                            [
                                136.949155,
                                -15.729083
                            ],
                            [
                                137.000434,
                                -15.620942
                            ],
                            ...
                            [
                                136.949155,
                                -15.729083
                            ]
                        ]
                    ],
                    [
                        [
                            [
                                136.816494,
                                -13.854235
                            ],
                            [
                                136.778979,
                                -14.023927
                            ],
                            ...
                            [
                                136.816494,
                                -13.854235
                            ]
                        ]
                    ],
                ]
            },
            "properties": {
                "area_sqkm": 1.352034e+06,
                "centroid": [
                    [
                        133.43024,
                        -19.414219
                    ],
                    [
                        137.03177,
                        -15.710557
                    ],
                    [
                        136.58104,
                        -14.002981
                    ]
                ],
                "name": "Lingiari",
                "state": "NT"
            }
        },
        {
            "id": "solomon",
            "type": "Feature",
            "bbox": [
                130.813098,
                -12.547189,
                131.051494,
                -12.143749
            ],
            "geometry": {
                "type": "MultiPolygon",
                "coordinates": [
                    [
                        [
                            [
                                131.034867,
                                -12.360879
                            ],
                            [
                                131.011878,
                                -12.531481
                            ],
                            ...
                            [
                                131.034867,
                                -12.360879
                            ]
                        ]
                    ]
                ]
            },
            "properties": {
                "area_sqkm": 336.6861,
                "centroid": [
                    [
                        130.94716,
                        -12.411875
                    ]
                ],
                "name": "Solomon",
                "state": "NT"
            }
        }
    ]
}
```

*This is not an official Google product*
