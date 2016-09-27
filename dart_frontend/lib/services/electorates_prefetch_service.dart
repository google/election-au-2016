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
import 'zoom_buckets_service.dart';
import 'electorate_spatial.dart';

@Injectable()
class ElectoratesPrefetchService {
  final Configuration _config;
  final ZoomBucketsService _zoomBucketsService;
  Future<int> zoomLevel;
  Future<List> features;
  Completer _completer = new Completer();

  get electorateMap => _completer.future;

  set electorateMap(Map<String, ElectorateSpatial> data) {
    _completer.complete(data);
  }

  ElectoratesPrefetchService(this._config, this._zoomBucketsService) {
    var zoomLevel = new Future(() async {
      return (await _zoomBucketsService.get()).first;
    });
    features = new Future(() async {
      var zoom = await zoomLevel;
      var json = await HttpRequest
          .getString('${_config.apiBaseUrl}electorates/$zoom?ids=all');

      return JSON.decode(json)['features'];
    });
  }
}
