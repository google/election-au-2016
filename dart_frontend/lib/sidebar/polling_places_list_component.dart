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

import 'dart:html';
import 'package:angular2/core.dart';
import 'package:google_maps/google_maps_geometry.dart';
import '../i18n/messages.dart';
import '../map/map_utils.dart' as mapUtils;
import '../services/election_firebase_service.dart';
import '../services/electorate_spatial_service.dart';
import '../services/page_state_service.dart';
import '../services/place_tooltip_service.dart';
import 'polling_place_details_component.dart';

@Component(
    selector: 'pollingplaceslist',
    templateUrl: 'polling_places_list_component.html',
    directives: const [PollingPlaceDetailsComponent])
class PollingPlacesListComponent {
  @Input()
  Electorate electorate;

  List<PollingPlaceMarker> _pollingPlaces;
  List<PollingPlaceMarker> _clippedPollingPlaces;

  final Messages _messages;
  final PlaceTooltipService _placeTooltipService;
  final PageStateService _pageStateService;

  static const _collapsedLength = 10;

  @Input()
  Election election;

  bool navigateOnClick;

  @Input()
  set pollingPlaces(List<PollingPlaceMarker> places) {
    _pollingPlaces = places;
    if (_pollingPlaces == null) {
      _pollingPlaces = [];
      _clippedPollingPlaces = [];
      return;
    }
    // If map is initialized, sort polling places by distance from map center (ascending).
    // TODO: This isn't great, accessing the map property of a dependency directly.
    if (_placeTooltipService.map != null) {
      var center = _placeTooltipService.map.center;
      _pollingPlaces.sort((a, b) => spherical
          .computeDistanceBetween(center, a.location)
          .compareTo(spherical.computeDistanceBetween(center, b.location)));
    }
    if (_pollingPlaces.length > _collapsedLength) {
      _clippedPollingPlaces =
          new List.from(places.getRange(0, _collapsedLength));
    } else {
      _clippedPollingPlaces = _pollingPlaces;
    }
  }

  List<PollingPlaceMarker> get visiblePollingPlaces {
    if (showAll) {
      return _pollingPlaces;
    } else {
      return _clippedPollingPlaces;
    }
  }

  bool get canExpand => _pollingPlaces.length > _collapsedLength;

  @Input()
  bool showAll;

  String get moreOrLess =>
      showAll ? _messages.show_less() : _messages.show_more();

  toggleAll() => showAll = !showAll;

  clickPollingPlace(PollingPlaceMarker place) {
    if (navigateOnClick) {
      // TODO
      var url = mapUtils.googleMapsSearchUrlForPlace(place);
      window.open(url, "_blank");
    } else {
      _placeTooltipService.moveThenShowInfoWindow(place);
    }
  }

  handlePageState(PageState pageState) {
    navigateOnClick = pageState.breakpoint == PageState.BREAKPOINT_MOBILE;
  }

  PollingPlacesListComponent(
      this._messages, this._placeTooltipService, this._pageStateService) {
    _pageStateService.pageState.listen(handlePageState);
    handlePageState(_pageStateService.currentPageState);
  }
}
