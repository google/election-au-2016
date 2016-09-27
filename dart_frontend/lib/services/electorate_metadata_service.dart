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

// NOTE this is currently not used.

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:angular2/angular2.dart' show Injectable;
import '../configuration.dart';
import 'electorates_prefetch_service.dart';
import 'zoom_buckets_service.dart';

class ElectorateMetadata {
  String electorateId;
  num area;
  String name;
  String state;

  ElectorateMetadata(dynamic feature) {
    electorateId = feature['id'];
    var properties = feature['properties'];
    area = properties['area'];
    name = properties['name'];
    state = properties['state'];
  }

  String toString() => 'Electorate $electorateId $area $name $state';
}

@Injectable()
class ElectorateMetadataService {
  final Configuration _config;
  final ZoomBucketsService _zoomBucketsService;
  final ElectoratesPrefetchService _electoratesPrefetchService;
  Future<Map<String, ElectorateMetadata>> electorates;

  ElectorateMetadataService(this._config, this._electoratesPrefetchService,
      this._zoomBucketsService) {
    electorates = new Future(() async {
      var features = await _electoratesPrefetchService.features;
      Map<String, ElectorateMetadata> electorates = new Map();
      for (var feature in features) {
        var electorate = new ElectorateMetadata(feature);
        electorates[electorate.electorateId] = electorate;
      }
      return electorates;
    });
  }

  // TODO remove...
  Future<ElectorateMetadata> get(String electorateId, num zoomLevel) async {
    num zoomBucket = await _zoomBucketsService.chooseBestZoomBucket(zoomLevel);
    var json = await HttpRequest.getString(
        '${_config.apiBaseUrl}electorates/$zoomBucket/$electorateId');
    return new ElectorateMetadata(JSON.decode(json)['features'][0]);
  }
}
