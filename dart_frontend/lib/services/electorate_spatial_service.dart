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
import 'package:google_maps/google_maps.dart';
import '../configuration.dart';
import 'electorates_prefetch_service.dart';
import 'electorate_spatial.dart';
import 'viewport_service.dart';

class ElectorateSpatialPayload {
  final int zoomBucket;
  final List<ElectorateSpatial> electorateSpatials;
  ElectorateSpatialPayload(this.zoomBucket, this.electorateSpatials);
}

class ElectorateLabel {
  String id;
  String name;
  final List<LatLng> locations = new List();

  ElectorateLabel(dynamic feature) {
    id = feature['id'];
    name = feature['properties']['name'];
    if (feature['geometry']['type'] == 'Point') {
      var point = feature['geometry']['coordinates'];
      locations.add(new LatLng(point[1], point[0]));
      return;
    }
    if (feature['geometry']['type'] != 'MultiPoint') {
      // Unsupported.. for now, ignore.
      return;
    }

    for (var point in feature['geometry']['coordinates']) {
      locations.add(new LatLng(point[1], point[0]));
    }
  }
}

class PollingPlaceMarker {
  String id;
  LatLng location;
  bool isGroup;
  PollingPlaceInfo placeInfo;
  int minZoom;
  dynamic data;

  PollingPlaceMarker(dynamic feature) {
    id = feature['id'];
    if (feature['geometry']['type'] != 'Point') {
      // Unsupported.. for now, ignore.
      return;
    }
    var point = feature['geometry']['coordinates'];
    location = new LatLng(point[1], point[0]);
    data = feature['properties'];
    if (feature['properties']['type'] == 'polling_place') {
      placeInfo = new PollingPlaceInfo(data);
      isGroup = false;
    } else {
      isGroup = true;
    }
    var mz = feature['properties']['minZoom'];
    if (mz != null) {
      minZoom = mz;
    }
  }
}

class PollingPlaceInfo {
  final Address address;
  final String premisesName;
  final bool wheelchairAccess;
  final num pollingPlaceId;
  final String electorateName;

  PollingPlaceInfo(dynamic geojsonProperties)
      : this.address = new Address(geojsonProperties),
        this.premisesName = geojsonProperties['PremisesName'],
        this.wheelchairAccess =
            _parseWheelchairAccess(geojsonProperties['WheelchairAccess']),
        this.pollingPlaceId = geojsonProperties['PollingPlaceId'],
        this.electorateName = geojsonProperties['DivisionName'].toLowerCase() {}

  static bool _parseWheelchairAccess(String value) {
    switch (value.toLowerCase()) {
      case "assisted":
      case "full":
        // TODO(ftamp): Split these out and make it a tri-state. We need UX treatment.
        return true;
      case "none":
        return false;
      default:
        print("Couldn't understand wheelchair access value: $value");
        return false;
    }
  }

  String toString() =>
      'PollingPlaceInfo{$address $premisesName $wheelchairAccess}';
}

class Address {
  final List<String> lines;
  final String suburb;
  final String stateAbbreviation;

  Address(dynamic geojsonProperties)
      : this.lines = new List.from(
            [
              geojsonProperties['Address1'],
              geojsonProperties['Address2'],
              geojsonProperties['Address3']
            ].where((String line) => line.trim().isNotEmpty),
            growable: false),
        this.suburb = geojsonProperties['AddressSuburb'],
        this.stateAbbreviation = geojsonProperties['AddressStateAbbreviation'];

  String toString() {
    var buffer = new StringBuffer();
    for (var line in this.lines) {
      buffer.write(line);
      buffer.write(", ");
    }
    return "${buffer.toString()}${this.suburb}, ${this.stateAbbreviation}";
  }
}

class PollingPlacePayload {
  final List<PollingPlaceMarker> pollingPlaces;

  PollingPlacePayload(this.pollingPlaces) {}
}

class LabelPayload {
  final int zoomBucket;
  final List<ElectorateLabel> electorateLabels;

  LabelPayload(this.zoomBucket, this.electorateLabels) {}
}

@Injectable()
class ElectorateSpatialService {
  final Configuration _config;
  final ElectoratesPrefetchService _electoratesPrefetchService;
  final ViewportService _viewportService;
  final StreamController<ElectorateSpatialPayload> _spatialController =
      new StreamController();
  final StreamController<PollingPlacePayload> _pollingPlaceController =
      new StreamController();
  final StreamController<LabelPayload> _labelController =
      new StreamController();

  int _maxZoomLevelToIgnorePollingPlaces;

  Stream<ElectorateSpatialPayload> get electorateSpatialPayload =>
      _spatialController.stream;

  Stream<PollingPlacePayload> get pollingPlacePayload =>
      _pollingPlaceController.stream;

  Stream<LabelPayload> get labelPayload => _labelController.stream;

  bool showPollingPlaces = true;

  ElectorateSpatialService(
      this._config, this._electoratesPrefetchService, this._viewportService) {
    _maxZoomLevelToIgnorePollingPlaces =
        _config.maxZoomLevelToIgnorePollingPlaces;
    // Ensure fetch is done here but ignore returned Future.
    // Let map component update via updateViewport().
    prefetch();
  }

  Future<ElectorateSpatialPayload> prefetch() async {
    var electorateFeatures = await _electoratesPrefetchService.features;
    var zoomLevel = await _electoratesPrefetchService.zoomLevel;
    var electorateSpatialPayload =
        translateFeatures(zoomLevel, electorateFeatures);
    var map = new Map();
    for (var electorateSpatial in electorateSpatialPayload.electorateSpatials) {
      map[electorateSpatial.id] = electorateSpatial;
    }
    _electoratesPrefetchService.electorateMap = map;
    return electorateSpatialPayload;
  }

  Future<LabelPayload> viewportToLabelPayload(Viewport viewport) async {
    var labelsList = new List();
    var features = viewport.data['features'];
    if (features != null) {
      for (var feature in features) {
        if (feature["properties"]["type"] != "electorate_label") {
          continue;
        }
        labelsList.add(new ElectorateLabel(feature));
      }
    }
    // Support future API.
    return new Future.value(new LabelPayload(viewport.zoomBucket, labelsList));
  }

  Future<PollingPlacePayload> legacyViewportToPollingPlacePayload(
      Viewport viewport) {
    var placeList = new List();
    var features = viewport.data['features'];
    if (features != null) {
      for (var feature in features) {
        var featureType = feature["properties"]["type"];
        if (featureType != "polling_place" &&
            featureType != "polling_place_group") {
          continue;
        }
        placeList.add(new PollingPlaceMarker(feature));
      }
    }
    return new Future.value(new PollingPlacePayload(placeList));
  }

  Future<PollingPlacePayload> electorateIdsToPollingPlacePayload(
      String electorateIds) async {
    var json = await HttpRequest
        .getString('${_config.apiBaseUrl}polling_places?ids=$electorateIds');
    var placeList = new List();
    var features = JSON.decode(json)['features'];
    if (features != null) {
      for (var feature in features) {
        var featureType = feature["properties"]["type"];
        if (featureType != "polling_place" &&
            featureType != "polling_place_group") {
          continue;
        }
        placeList.add(new PollingPlaceMarker(feature));
      }
    }
    return new PollingPlacePayload(placeList);
  }

  Future<PollingPlacePayload> parallelElectorateIdsToPollingPlacePayLoad(
      List<String> electorateIds) async {
    var payloadsFutures = new List();
    for (var electorateId in electorateIds) {
      var future = electorateIdsToPollingPlacePayload(electorateId);
      payloadsFutures.add(future);
    }
    var payloads = await Future.wait(payloadsFutures);
    // Flatten results and return as a single payload
    var placeList = new List();
    for (var payload in payloads) {
      placeList.addAll(payload.pollingPlaces);
    }
    return new PollingPlacePayload(placeList);
  }

  Future<PollingPlacePayload> viewportToPollingPlacePayload(
      Viewport viewport) async {
    var placeList = new List();
    if (viewport.zoom <= _maxZoomLevelToIgnorePollingPlaces) {
      return new PollingPlacePayload(placeList);
    }
    var electorateIds;
    for (var feature in viewport.data['features']) {
      if (feature["properties"]["type"] != "electorate_ids") {
        continue;
      }
      electorateIds = feature["properties"]["electorates"];
      break;
    }
    if (electorateIds == null) {
      return new PollingPlacePayload(placeList);
    }
    // Note: seems like this is useful only for high zoom levels, o/w too many requests are fired at once.
    if (electorateIds.length > 1 && electorateIds.length <= 4) {
      return await parallelElectorateIdsToPollingPlacePayLoad(electorateIds);
    }
    var electorateIdsString = electorateIds.join(",");
    return await electorateIdsToPollingPlacePayload(electorateIdsString);
  }

  ElectorateSpatialPayload translateFeatures(int zoomBucket, dynamic features) {
    var electorateSpatials = new List();
    if (features != null) {
      for (var feature in features) {
        electorateSpatials.add(new ElectorateSpatial(feature));
      }
    }
    return new ElectorateSpatialPayload(zoomBucket, electorateSpatials);
  }

  Future<ElectorateSpatialPayload> viewportToSpatialPayload(
      Viewport viewport) async {
    List electorateIds;
    for (var feature in viewport.data['features']) {
      if (feature["properties"]["type"] != "electorate_ids") {
        continue;
      }
      electorateIds = feature["properties"]["electorates"];
      break;
    }
    if (electorateIds == null) {
      return new Future.value();
    }
    var electorateIdsString = electorateIds.join(",");
    var zoomBucket = viewport.zoomBucket;
    var json = await HttpRequest.getString(
        '${_config.apiBaseUrl}electorates/$zoomBucket?ids=$electorateIdsString');
    var features = JSON.decode(json)['features'];
    return translateFeatures(zoomBucket, features);
  }

  Future updateViewport(int zoom, LatLngBounds bounds) async {
    var viewport = await _viewportService.getViewport(zoom, bounds);
    var futures = [
      updateElectoratesSpatial(viewport),
      updateLabels(viewport),
      updatePollingPlaces(viewport),
    ];
    await Future.wait(futures);
  }

  Future updateElectoratesSpatial(Viewport viewport) async {
    var prefetchZoom = await _electoratesPrefetchService.zoomLevel;
    var electorateSpatialPayload;
    if (viewport.zoomBucket == prefetchZoom) {
      electorateSpatialPayload = await prefetch();
    } else {
      electorateSpatialPayload = await viewportToSpatialPayload(viewport);
    }
    _spatialController.add(electorateSpatialPayload);
  }

  Future updateLabels(Viewport viewport) async {
    var labelPayload = await viewportToLabelPayload(viewport);
    _labelController.add(labelPayload);
  }

  Future updatePollingPlaces(Viewport viewport) async {
    if (!showPollingPlaces) {
      _pollingPlaceController.add(new PollingPlacePayload(new List()));
      return;
    }
    var pollingPlacePayload = await viewportToPollingPlacePayload(viewport);
    _pollingPlaceController.add(pollingPlacePayload);
  }
}
