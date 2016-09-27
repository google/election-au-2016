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
import 'dart:html' show querySelector;
import 'package:angular2/angular2.dart';
import 'package:google_maps/google_maps.dart';
import '../map/info_window_creator.dart';
import '../services/electorate_spatial_service.dart';
import 'election_firebase_service.dart';
import 'page_state_service.dart';

@Injectable()
class PlaceTooltipService {
  @Input()
  set election(Election election) {
    _infoWindowCreator.election = election;
  }

  PageStateService _pageStateService;
  InfoWindowCreator _infoWindowCreator;

  PlaceTooltipService(this._infoWindowCreator, this._pageStateService);

  GMap map;

  InfoWindow _lastInfoWindow;
  Map<String, Marker> _markers = new Map();

  // non-blocking stream.
  final StreamController _markersUpdated = new StreamController.broadcast();

  set markers(Map<String, Marker> markers) {
    this._markers = markers;
    _markersUpdated.add(true);
  }

  bool _clearPreviousInfoWindow() {
    if (map == null) {
      return false;
    }
    if (_lastInfoWindow != null) {
      _lastInfoWindow.close();
      _lastInfoWindow = null;
    }
    return true;
  }

  _doShowInfoWindow(PollingPlaceMarker place) {
    _infoWindowCreator.create(place).then((window) {
      _lastInfoWindow = window;
      window.open(map, _markers[place.id]);
    });
  }

  moveThenShowInfoWindow(PollingPlaceMarker place) async {
    if (_clearPreviousInfoWindow() == false) {
      return;
    }
    if (place.minZoom <= 0) {
      return;
    }
    var pageState = _pageStateService.currentPageState;
    var targetElectorate = pageState.selectedElectorate;
    if (place.placeInfo != null) {
      targetElectorate = place.placeInfo.electorateName;
    }
    // The logic for moving the map to the right location, zooming in and then showing the info window
    // is considerably more complicated so only progress down that lane if we must.
    if (place.minZoom > 0 &&
        map.zoom >= place.minZoom &&
        map.bounds.contains(place.location)) {
      _pageStateService.selectedElectorate = targetElectorate;
      _doShowInfoWindow(place);
      return;
    }
    var targetZoom = map.zoom;
    if (map.zoom < place.minZoom) {
      targetZoom = place.minZoom;
    }
    var targetCenter = place.location;
    // TODO: this can easily break. For now, if the map had to move and viewport is large enough,
    // scroll "polling places" heading into view.
    var sidebarContent = querySelector("#sidebar-content");
    var pollingPlacesTop = querySelector("#polling-places-top");
    if (pollingPlacesTop != null &&
        sidebarContent != null &&
        pageState.breakpoint != PageState.BREAKPOINT_MOBILE) {
      var offsetTop = pollingPlacesTop.offsetTop;
      sidebarContent.scrollTop = offsetTop - 180;
    }
    _pageStateService.setMapViewportAndElectorate(
        targetCenter, targetZoom, targetElectorate);
    // We hope that the viewport setting above will cause a re-fetch and update of markers.
    await _markersUpdated.stream.first;
    // Eventually this will happen but we cannot be sure that this would happen with our place ID in the markers map.
    if (_markers[place.id] != null) {
      _doShowInfoWindow(place);
    }
  }

  void showInfoWindow(PollingPlaceMarker place) {
    if (_clearPreviousInfoWindow() == false) {
      return;
    }
    if (place.placeInfo != null) {
      _pageStateService.selectedElectorate = place.placeInfo.electorateName;
    }
    _doShowInfoWindow(place);
  }

  void clearInfoWindow() {
    _clearPreviousInfoWindow();
  }
}
