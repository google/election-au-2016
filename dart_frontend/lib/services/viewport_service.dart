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

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'package:angular2/angular2.dart' show Injectable;
import 'package:google_maps/google_maps.dart';
import '../configuration.dart';
import 'zoom_buckets_service.dart';

class Viewport {
  final int zoomBucket;
  final int zoom;
  final LatLngBounds bounds;
  // Currently dynamic, TODO structure.
  final dynamic data;
  Viewport(this.zoomBucket, this.zoom, this.bounds, this.data);
}

@Injectable()
class ViewportService {
  final int precision = 2;
  final Configuration _config;
  final ZoomBucketsService _zoomBucketsService;

  ViewportService(this._config, this._zoomBucketsService) {}

  num floor10(val, precision) {
    var exp = pow(10, precision);
    return (val * exp).floor() / exp;
  }

  num ceil10(val, precision) {
    var exp = pow(10, precision);
    return (val * exp).ceil() / exp;
  }

  // rounds the coordinates of `bounds` to `precision`, such that the return value
  // contains the entire input bounds.
  LatLngBounds quantizeBounds(LatLngBounds bounds) {
    var sw = bounds.southWest;
    var ne = bounds.northEast;
    var newSw =
        new LatLng(floor10(sw.lat, precision), floor10(sw.lng, precision));
    var newNe =
        new LatLng(ceil10(ne.lat, precision), ceil10(ne.lng, precision));
    return new LatLngBounds(newSw, newNe);
  }

  Future<Viewport> getViewport(int zoom, LatLngBounds bounds) async {
    var qBounds = quantizeBounds(bounds);
    var zoomBucket = await _zoomBucketsService.chooseBestZoomBucket(zoom);
    var json = await HttpRequest.getString(
        '${_config.apiBaseUrl}viewport/$zoom?bbox=${qBounds.toUrlValue(2)}');
    return new Viewport(zoomBucket, zoom, qBounds, JSON.decode(json));
  }
}
