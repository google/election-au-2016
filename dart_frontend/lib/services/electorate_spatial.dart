/*
 * Copyright 2016 Google Inc. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import 'package:google_maps/google_maps.dart';
import 'package:google_maps/google_maps_geometry.dart';

class ElectorateSpatial {
  String id;
  String name;
  LatLngBounds bounds;
  List<Polygon> multiPolygon;

  List<Polygon> decodeMultiPolygon(List<List<String>> encodedMultiPolygon) {
    var result = new List();
    for (var encodedPolygon in encodedMultiPolygon) {
      var polygonPaths = new List();
      for (var encodedPath in encodedPolygon) {
        var path = encoding.decodePath(encodedPath);
        polygonPaths.add(path);
      }
      var polygon = new Polygon(new PolygonOptions()..paths = polygonPaths);
      result.add(polygon);
    }
    return result;
  }

  List<Polygon> extractCoords(dynamic coords) {
    // Assuming multipolygon. We "currently" don't handle anything else.
    var result = new List();
    for (var polygonCoords in coords) {
      var polygonPaths = new List();
      for (var linearRing in polygonCoords) {
        var path = new List();
        for (var coordinate in linearRing) {
          // Account for difference between geojson and gmap's specification.
          path.add(new LatLng(coordinate[1], coordinate[0]));
        }
        polygonPaths.add(path);
      }
      var polygon = new Polygon(new PolygonOptions()..paths = polygonPaths);
      result.add(polygon);
    }
    return result;
  }

  ElectorateSpatial(dynamic feature) {
    id = feature['id'];
    name = feature['properties']['name'];
    var bbox = feature['bbox'];
    if (bbox != null && bbox.length == 4) {
      var sw = new LatLng(bbox[1], bbox[0]);
      var ne = new LatLng(bbox[3], bbox[2]);
      bounds = new LatLngBounds(sw, ne);
    }
    if (feature['geometry']['type'] == 'EncodedMultiPolygon') {
      multiPolygon = decodeMultiPolygon(feature['geometry']['coordinates']);
    } else {
      multiPolygon = extractCoords(feature['geometry']['coordinates']);
    }
  }
}
