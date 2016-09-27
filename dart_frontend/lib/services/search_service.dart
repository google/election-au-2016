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
import 'package:google_maps/google_maps_places.dart';
import '../configuration.dart';
import '../i18n/messages.dart';
import 'election_firebase_service.dart';
import 'electorates_prefetch_service.dart';
import 'page_state_service.dart';

abstract class SearchResult {
  final String description;
  final String electorateName;
  final GMap _map;
  final SearchService _searchService;
  final PageStateService _pageStateService;
  SearchResult(this.description, this.electorateName, this._map,
      this._searchService, this._pageStateService);
  String toString() => '$description $electorateName';
  void selected();
}

class SearchResultPlace extends SearchResult {
  static const searchResultZoom = 10;
  final LatLng _location;
  SearchResultPlace(
      String description,
      String electorateName,
      String placeId,
      GMap map,
      this._location,
      SearchService searchService,
      PageStateService pageStateService)
      : super(
            description, electorateName, map, searchService, pageStateService);
  void selected() {
    _pageStateService.setMapViewportAndElectorate(
        _location, searchResultZoom, electorateName.toLowerCase());
    _searchService.selectSearchLocation(_location, description);
  }
}

class SearchResultElectorate extends SearchResult {
  LatLngBounds _bounds;
  SearchResultElectorate(
      String description,
      String electorateName,
      GMap map,
      this._bounds,
      SearchService searchService,
      PageStateService pageStateService)
      : super(
            description, electorateName, map, searchService, pageStateService);
  void selected() {
    _searchService.selectSearchLocation(null, null);
    _pageStateService.selectedElectorate = electorateName.toLowerCase();
    new Timer(new Duration(milliseconds: 300), () {
      _map.fitBounds(_bounds);
    });
  }
}

class SearchBounds extends SearchResult {
  LatLngBounds _bounds;
  SearchBounds(String description, GMap map, this._bounds,
      SearchService searchService, PageStateService pageStateService)
      : super(description, "", map, searchService, pageStateService);

  void selected() {
    _searchService.selectSearchLocation(null, null);
    _pageStateService.setNationView();
    new Timer(new Duration(milliseconds: 300), () {
      _map.fitBounds(_bounds);
    });
  }
}

class SearchLocation {
  final LatLng location;
  final String title;

  SearchLocation(this.location, this.title);
  String toString() =>
      'SearchLocation (${location != null ? location.lat : 0},' +
      '${location != null ? location.lng : 0}) "${title}"';
}

@Injectable()
class SearchService {
  final AutocompleteService _autocompleteService = new AutocompleteService();
  PlacesService _placesService;
  GMap _map;
  final Configuration _config;
  final Messages _messages;
  final Completer _electorateMapCompleter = new Completer();
  final PageStateService _pageStateService;
  Election election;

  SearchService(
      this._config,
      this._messages,
      ElectionFirebaseService electionFirebaseService,
      ElectoratesPrefetchService electoratePrefetchService,
      this._pageStateService) {
    electionFirebaseService.election.listen((election) {
      this.election = election;
    });
    electoratePrefetchService.electorateMap.then((data) {
      _electorateMapCompleter.complete(data);
    });
  }

  Map<String, Future<SearchResult>> _placeIdQueryCache = {};

  Future<SearchResult> searchForPlaceId(String placeId) async {
    try {
      // Step 1, look up place details for placeId
      var detailsRequest = new PlaceDetailsRequest()..placeId = placeId;
      Completer<PlaceResult> detailsCompleter = new Completer();
      _placesService.getDetails(detailsRequest,
          (PlaceResult placeResult, PlacesServiceStatus _) {
        detailsCompleter.complete(placeResult);
      });
      var placeResult = await detailsCompleter.future;

      if (placeResult == null) {
        _placeIdQueryCache.remove(placeId);
        return null;
      }

      var description = placeResult.formattedAddress
          .replaceFirst(', Australia', '')
          .replaceFirst(new RegExp(r'[0-9]{4}\s*$'), '');
      var location = placeResult.geometry.location;

      // Step 2, look up electorate for place details
      var url =
          '${_config.apiBaseUrl}location?location=${location.lat},${location.lng}';
      var json = JSON.decode(await HttpRequest.getString(url));
      var electorateName = _messages.unknown_electorate();
      if (json.containsKey('Name')) {
        electorateName = json['Name'];
      }
      return new SearchResultPlace(description, electorateName, placeId,
          this._map, location, this, this._pageStateService);
    } catch (exception, stacktrace) {
      print(exception);
      print(stacktrace);
      // Remove the future from the cache, so it will get retried.
      if (_placeIdQueryCache.containsKey(placeId))
        _placeIdQueryCache.remove(placeId);
    }
    return null;
  }

  StreamController _streamController = new StreamController.broadcast();

  Stream<SearchLocation> get searchLocation => _streamController.stream;

  // TODO not sure we get a lot by letting the search sevice maintain state. The search component and
  // results have to, so it may be better there; or similarly, this could be directly on the map component.
  void selectSearchLocation(LatLng location, String title) {
    _streamController.add(new SearchLocation(location, title));
  }

  void set map(GMap map) {
    this._map = map;
    this._placesService = new PlacesService(map);
  }

  Future<SearchResult> searchElectorate(String query) async {
    var lowerCaseQuery = query.toLowerCase();
    if ("australia".startsWith(lowerCaseQuery)) {
      // Yes, hardcode Sydney electorate to dictated bounding box that don't include Lord Howe Island. Sorry!
      var sw = new LatLng(-46.3165, 103.5351);
      var ne = new LatLng(-6.4899, 163.125);
      return new SearchBounds(
          "Australia", _map, new LatLngBounds(sw, ne), this, _pageStateService);
    }
    var map = await _electorateMapCompleter.future;
    Set<String> electorateIds = map.keys;
    var electorateSpatial = null;
    var description;
    // Special cases:
    // Hard coding known replacements:
    if ("fraser".startsWith(lowerCaseQuery)) {
      electorateSpatial = map["fenner"];
      description = "Fenner, formerly Fraser";
    } else if ("throsby".startsWith(lowerCaseQuery)) {
      electorateSpatial = map["whitlam"];
      description = "Whitlam, formerly Throsby";
    } else {
      for (var id in electorateIds) {
        if (id.startsWith(lowerCaseQuery)) {
          electorateSpatial = map[id];
          description = electorateSpatial.name;
          break;
        }
      }
    }
    if (electorateSpatial == null) {
      return null;
    }
    var bounds = electorateSpatial.bounds;
    if (electorateSpatial.id == "sydney") {
      // Yes, hardcode Sydney electorate to dictated bounding box that don't include Lord Howe Island. Sorry!
      var sw = new LatLng(-33.924332, 151.171465);
      var ne = new LatLng(-33.849776, 151.23088);
      bounds = new LatLngBounds(sw, ne);
    }
    // Could send electorateSpatial.id. Currently this breaks.
    return new SearchResultElectorate(description, electorateSpatial.name, _map,
        bounds, this, _pageStateService);
  }

  Future<List<SearchResult>> searchAutocomplete(String query) async {
    var request = new AutocompletionRequest()
      ..bounds = _map.bounds
      ..input = query
      ..types = ['geocode']
      ..componentRestrictions = (new ComponentRestrictions()..country = 'au');

    Completer<List<AutocompletePrediction>> autocompleteCompleter =
        new Completer();
    _autocompleteService.getPlacePredictions(request,
        (List<AutocompletePrediction> predictions,
            PlacesServiceStatus placeServiceStatus) {
      autocompleteCompleter.complete(predictions);
    });

    var predictions = await autocompleteCompleter.future;
    if (predictions == null) {
      return [];
    }
    List<Future<SearchResult>> futures = [];
    for (AutocompletePrediction prediction in predictions) {
      if (_placeIdQueryCache.containsKey(prediction.placeId)) {
        futures.add(_placeIdQueryCache[prediction.placeId]);
      } else {
        var future = searchForPlaceId(prediction.placeId);
        futures.add(future);
        _placeIdQueryCache[prediction.placeId] = future;
      }
    }
    // Some nulls are possible here.
    return await Future.wait(futures);
  }

  Future<List<SearchResult>> search(String query) async {
    if (query == null) {
      return [];
    }
    query = query.trim();
    if (query.length <= 2) {
      return [];
    }
    if (_placesService == null) {
      throw new Exception("Map not set");
    }
    try {
      var electorateResult = await searchElectorate(query);
      var autocompleteResults = await searchAutocomplete(query);
      var results = new List<SearchResult>();
      results.add(electorateResult);
      results.addAll(autocompleteResults);
      return results.where((res) => res != null).toList();
    } catch (exception, stacktrace) {
      print(exception);
      print(stacktrace);
    }
    return [];
  }

  // TODO this shouldn't really be here.
  LatLngBounds getBounds() {
    if (_map == null) {
      return null;
    }
    return _map.bounds;
  }
}
