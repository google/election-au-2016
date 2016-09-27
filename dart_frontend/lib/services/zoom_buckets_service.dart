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
import 'package:angular2/angular2.dart' show Injectable;
import '../configuration.dart';

@Injectable()
class ZoomBucketsService {
  final Configuration _config;
  Future<List<num>> _futureZoomBuckets;

  ZoomBucketsService(this._config) {
    _futureZoomBuckets = new Future(() async {
      var json =
          await HttpRequest.getString('${_config.apiBaseUrl}zoom_buckets');
      return JSON.decode(json);
    });
  }

  // Choose the first zoom level that exceeds the current map zoom level.
  // Expects zoom levels to be sorted ascending.
  Future<num> chooseBestZoomBucket(num zoomLevel) async {
    List<num> zoomBuckets = await _futureZoomBuckets;
    for (var i = 0; i < zoomBuckets.length; i++) {
      if (zoomLevel <= zoomBuckets[i]) {
        return zoomBuckets[i];
      }
    }
    return zoomBuckets.last;
  }

  Future<List<num>> get() async {
    List<num> zoomBuckets = await _futureZoomBuckets;
    return zoomBuckets;
  }
}
