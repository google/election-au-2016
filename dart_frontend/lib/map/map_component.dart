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
import 'dart:core';
import 'dart:html' show Element, DivElement, ImageElement;
import 'package:angular2/core.dart' show Component, ElementRef, Input;
import 'package:google_maps/google_maps.dart';
import '../configuration.dart';
import '../map_style.dart';
import '../i18n/messages.dart';
import '../map/info_window_creator.dart';
import '../services/election_firebase_service.dart';
import '../services/electorate_spatial_service.dart';
import '../services/page_state_service.dart';
import '../services/place_tooltip_service.dart';
import '../services/search_service.dart';

class AustraliaControl {
  AustraliaControl(Element controlDiv, PageStateService pageStateService,
      SearchService searchService) {
    final controlUI = new DivElement();
    controlUI.className = 'nation-view';
    controlDiv.children.add(controlUI);

    final controlImage = new ImageElement();
    controlImage.src = '/static/ic_country.svg';
    controlUI.children.add(controlImage);
    event.addDomListener(controlImage, 'click', (e) {
      pageStateService.setNationView();
      // Clear the search query from the side bar, and remove the marker from
      // the map.
      searchService.selectSearchLocation(null, null);
    });
  }
}

enum PolygonColorOption { normal, hover, selected }

@Component(
    selector: 'map',
    template: '<div></div>',
    providers: const [InfoWindowCreator])
class MapComponent {
  final PageStateService _pageStateService;
  final ElectorateSpatialService _electorateSpatialService;
  final Configuration _configuration;
  String _pollingPlaceIconUrl;

  /// The Google Map painted into the map div
  GMap _map;

  // The zoom bucket previously set by a spatial data response.
  int _zoomBucketSpatialData;

  // The zoom bucket previously set by a point data response.
  int _zoomBucketPointData;

  /// A map of all currently displayed polygons, keyed on the electorate id.
  final Map<String, List<Polygon>> _polygons = new Map();

  /// Electorate color by electorateId
  final Map<String, String> _electorateColor = new Map();

  /// Electorate winning by electorateId
  final Map<String, bool> _electorateWinning = new Map();

  /// A map of all displayed markers, keyed on polling place ID (an AEC thing..).
  final Map<String, Marker> _markers = new Map();

  /// A map of all displayed electorate labels, keyed on the electorate id.
  final Map<String, List<Marker>> _labels = new Map();

  /// Marker showing a search location.
  Marker searchLocationMarker;

  dynamic _mapNativeElement;

  MapOptions _mapOptions;

  final PlaceTooltipService _placeTooltipService;

  /// The ID of the most recent selected electorate, set by the page state service. Can be the empty string.
  String _selectedElectorate;

  int _maxZoomLevelToIgnorePollingPlaces;

  // The zoom level to use by default.
  int defaultZoom = 4;

  final Messages _messages;

  MapComponent(
      ElementRef ref,
      this._electorateSpatialService,
      this._pageStateService,
      this._placeTooltipService,
      this._configuration,
      this._messages,
      SearchService searchService) {
    _maxZoomLevelToIgnorePollingPlaces =
        _configuration.maxZoomLevelToIgnorePollingPlaces;
    _mapOptions = new MapOptions()
      ..styles = lightMapStyle
      ..minZoom = 3
      ..mapTypeControl = false
      ..streetViewControl = false;

    _mapNativeElement = ref.nativeElement;

    _map = new GMap(_mapNativeElement, _mapOptions);
    _placeTooltipService.map = _map;
    _pollingPlaceIconUrl = _configuration.pollingPlaceIconUrl;

    // Places Library requires a map instance
    searchService.map = _map;

    searchService.searchLocation.listen((SearchLocation searchLocation) {
      if (searchLocation.location == null && searchLocationMarker == null) {
        return;
      }

      if (searchLocation.location == null) {
        searchLocationMarker.map = null;
        searchLocationMarker = null;
        return;
      }

      if (searchLocationMarker == null) {
        Icon icon = new Icon()
          ..url = '/static/ic_pin.png'
          ..scaledSize = new Size(48, 48);
        MarkerOptions options = new MarkerOptions()
          ..map = _map
          ..icon = icon;
        searchLocationMarker = new Marker(options);
      }

      searchLocationMarker.title = searchLocation.title;
      searchLocationMarker.position = searchLocation.location;
    });

    var australiaControlDiv = new DivElement();
    new AustraliaControl(australiaControlDiv, _pageStateService, searchService);
    australiaControlDiv.attributes["index"] = '1';
    _map.controls[ControlPosition.RIGHT_BOTTOM].push(australiaControlDiv);

    _map.onIdle.listen((_) async {
      _pageStateService.setMapViewport(_map.center,
          _map.zoom == defaultZoom ? PageStateService.DEFAULT_ZOOM : _map.zoom);
      _electorateSpatialService.updateViewport(_map.zoom, _map.bounds);
      return true;
    });
    _map.onZoomChanged.listen((_) async {
      if (_map.zoom <= _maxZoomLevelToIgnorePollingPlaces) {
        updatePollingPlaces(new PollingPlacePayload(new List()));
      }
    });
  }

  @Input()
  set pageState(PageState pageState) {
    if (pageState != null) {
      bool isMobile = pageState.breakpoint == PageState.BREAKPOINT_MOBILE;
      _mapOptions.zoomControl = !isMobile;
      _map.options = _mapOptions;

      defaultZoom = isMobile ? 3 : 4;

      _map.center = pageState.center;
      _map.zoom = pageState.zoom == PageStateService.DEFAULT_ZOOM
          ? defaultZoom
          : pageState.zoom;
      if (_selectedElectorate != pageState.selectedElectorate) {
        _selectedElectorate = pageState.selectedElectorate;
        // debug:
        // print("selected: " + _selectedElectorate);
        updatePolygonColors();
      }
    }

    new Timer(new Duration(milliseconds: 1), () {
      event.trigger(_mapNativeElement, 'resize', []);
    });
  }

  /// Used to update all colors on the map.
  @Input()
  set election(Election election) {
    if (election == null) return;

    // So the polling place pop up can display sausage sizzle status
    _placeTooltipService.election = election;

    try {
      var changed = false;
      election.nation.winningPartyByElectorate.forEach((k, v) {
        var leadingParty = null;
        if (election.nation.leadingPartyByElectorate != null) {
          leadingParty = election.nation.parties[
              election.nation.leadingPartyByElectorate[k]];
        }

        var winningParty = election.nation.parties[v];
        String color = '';
        bool winning = false;
        if (winningParty != null) {
          color = winningParty.color;
          winning = true;
        } else if (leadingParty != null) {
          color = leadingParty.color;
        }
        if (_electorateColor[k] != color || _electorateWinning[k] != winning) {
          changed = true;
        }
        _electorateColor[k] = color;
        _electorateWinning[k] = winning;
      });
      if (changed) {
        updatePolygonColors();
      }
    } catch (exception, stacktrace) {
      print("Couldn't parse election: $exception");
      print(stacktrace);
    }
  }

  @Input()
  set electorateSpatial(ElectorateSpatialPayload electorateSpatialPayload) {
    if (electorateSpatialPayload == null) {
      return;
    }
    updateElectorateSpatialData(electorateSpatialPayload);
  }

  @Input()
  set pollingPlace(PollingPlacePayload pollingPlacePayload) {
    if (pollingPlacePayload == null) {
      return;
    }
    updatePollingPlaces(pollingPlacePayload);
  }

  @Input()
  set electorateLabel(LabelPayload labelPayload) {
    if (labelPayload == null) {
      return;
    }
    updateElectorateLabels(labelPayload);
  }

  clearElectorateSpatialData(
      ElectorateSpatialPayload electorateSpatialPayload) {
    var removeSet;
    if (_zoomBucketSpatialData != electorateSpatialPayload.zoomBucket) {
      removeSet = new Set.from(_polygons.keys);
    } else {
      var currSet = new Set();
      for (var electorateSpatial
          in electorateSpatialPayload.electorateSpatials) {
        currSet.add(electorateSpatial.id);
      }
      var prevSet = new Set.from(_polygons.keys);
      removeSet = prevSet.difference(currSet);
    }
    for (var id in removeSet) {
      var oldPolygonList = _polygons.remove(id);
      for (var oldPolygon in oldPolygonList) {
        oldPolygon.map = null;
      }
    }
  }

  /// Currently hover and selected have the same values, but this may change.
  static Map<String, Map<PolygonColorOption, num>> opacityLevels = {
    "leadLowOpacity": {
      PolygonColorOption.normal: 0.05,
      PolygonColorOption.hover: 0.15,
      PolygonColorOption.selected: 0.15,
    },
    "leadHiOpacity": {
      PolygonColorOption.normal: 0.4,
      PolygonColorOption.hover: 0.3,
      PolygonColorOption.selected: 0.3,
    },
    "lowOpacity": {
      PolygonColorOption.normal: 0.1,
      PolygonColorOption.hover: 0.3,
      PolygonColorOption.selected: 0.3,
    },
    "hiOpacity": {
      PolygonColorOption.normal: 0.8,
      PolygonColorOption.hover: 0.6,
      PolygonColorOption.selected: 0.6,
    },
    "ncOpacity": {
      PolygonColorOption.normal: 0,
      PolygonColorOption.hover: 0.2,
      PolygonColorOption.selected: 0.2,
    },
  };

  static const lightBorder = "#ffffff";
  static const darkBorder = "#455A64";
  static const darkerBorder = "#263238";

  // From this zoom onwards (zoom levels higher than this), we use lower opacity,
  // allowing more base map details to be seen. Note that the electorate label color
  // is also affected. Also note that this value must be equal to a zoomBucket's lower bound.
  static const minZoomForLowOpacity = 9;

  PolygonOptions createOptionsForColor(
      String id, PolygonColorOption polygonColorOption) {
    var opts = new PolygonOptions()
      ..zIndex = 10
      ..strokeOpacity = 1
      ..strokeWeight = 1;
    var color = _electorateColor[id];
    var selected = polygonColorOption == PolygonColorOption.selected;
    if (color == null || color.isEmpty) {
      opts.strokeColor = darkBorder;
      opts.strokePosition = StrokePosition.CENTER;
      if (selected) {
        opts.strokeWeight = 1.5;
        opts.strokeColor = darkerBorder;
        opts.zIndex = 100;
      }
      opts.fillColor = darkBorder;
      opts.fillOpacity = opacityLevels["ncOpacity"][polygonColorOption];
      return opts;
    }
    opts.strokeColor = lightBorder;
    opts.strokePosition = StrokePosition.INSIDE;
    if (selected) {
      opts.strokePosition = StrokePosition.CENTER;
      opts.strokeWeight = 1.5;
      opts.strokeColor = color;
      opts.zIndex = 100;
    }
    opts.fillColor = color;
    var opacityLevel = "lowOpacity";
    if (!_electorateWinning[id]) {
      opacityLevel = "leadLowOpacity";
      if (_map.zoom < minZoomForLowOpacity) {
        opacityLevel = "leadHiOpacity";
      }
    } else if (_map.zoom < minZoomForLowOpacity) {
      opacityLevel = "hiOpacity";
    }

    opts.fillOpacity = opacityLevels[opacityLevel][polygonColorOption];
    return opts;
  }

  updateElectorateSpatialData(
      ElectorateSpatialPayload electorateSpatialPayload) {
    clearElectorateSpatialData(electorateSpatialPayload);
    _zoomBucketSpatialData = electorateSpatialPayload.zoomBucket;
    for (var electorateSpatial in electorateSpatialPayload.electorateSpatials) {
      var id = electorateSpatial.id;
      // Skip electorates deemed to already be on the map.
      if (_polygons.containsKey(id)) {
        continue;
      }
      var selectElectorate = (_) {
        _pageStateService.selectedElectorate = id;
      };
      var mouseOver = (_) {
        // Don't change the color of the selected electorate.
        if (id == _selectedElectorate) {
          return;
        }
        for (var polygon in _polygons[id]) {
          polygon.options = createOptionsForColor(id, PolygonColorOption.hover);
        }
      };
      var mouseOut = (_) {
        // Don't change the color of the selected electorate.
        if (id == _selectedElectorate) {
          return;
        }
        for (var polygon in _polygons[id]) {
          polygon.options =
              createOptionsForColor(id, PolygonColorOption.normal);
        }
      };
      var polygonList = new List();
      var colorOption = PolygonColorOption.normal;
      if (id == _selectedElectorate) {
        colorOption = PolygonColorOption.selected;
      }
      for (var polygon in electorateSpatial.multiPolygon) {
        polygon.options = createOptionsForColor(id, colorOption);
        polygon.onClick.listen(selectElectorate);
        polygon.onMouseover.listen(mouseOver);
        polygon.onMouseout.listen(mouseOut);
        // By setting 'map', the polygon gets displayed.
        polygon.map = _map;
        polygonList.add(polygon);
      }
      _polygons[id] = polygonList;
    }
  }

  updatePolygonColors() {
    _polygons.forEach((String id, List<Polygon> polygonList) {
      if (id == _selectedElectorate) {
        for (var polygon in polygonList) {
          polygon.options =
              createOptionsForColor(id, PolygonColorOption.selected);
        }
        return;
      }
      for (var polygon in polygonList) {
        polygon.options = createOptionsForColor(id, PolygonColorOption.normal);
      }
    });
  }

  // Not sure if we would ever need to cycle through all labels' colors.
  updatePolygonAndLabelColors() {
    updatePolygonColors();
    _labels.forEach((String id, List<Marker> labelList) {
      var color = _electorateColor[id];
      var electorateLabelText = electorateLabelTextDark;
      // Only switch to light text if we are at low zoom level (lower than the thershold for low opacity)
      // AND there is some (non-empty) electorate color.
      if (_map.zoom < minZoomForLowOpacity && color != null && !color.isEmpty) {
        electorateLabelText = electorateLabelTextLight;
      }
      for (var label in labelList) {
        var location = label.position;
        var electorateLabelName = label.title;
        var svg = "data:image/svg+xml," +
            Uri.encodeFull(
                "${electorateLabelSvg} ${electorateLabelText} ${electorateLabelName} ${electorateLabelSvgEnd}");
        label.options = new MarkerOptions()
          ..position = location
          ..clickable = false
          ..title = electorateLabelName
          ..optimized = false
          ..icon = svg;
      }
    });
  }

  bool shouldShow(PollingPlaceMarker pollingPlaceMarker) {
    var currentZoom = _map.zoom;
    return (pollingPlaceMarker.isGroup &&
            pollingPlaceMarker.minZoom == currentZoom) ||
        (!pollingPlaceMarker.isGroup &&
            pollingPlaceMarker.minZoom <= currentZoom);
  }

  clearPollingPlaces(PollingPlacePayload pollingPlacePayload) {
    // TODO: consider for new polling places API, we receive all polling places, not limited to the viewport
    // so clipping to viewport will give the client a lot less to deal with.
    var currSet = new Set();
    for (var pollingPlaceMarker in pollingPlacePayload.pollingPlaces) {
      // Skip markers that are meant for higher zoom levels. Not adding them
      // to the current set means that they will get removed from the previous set
      // (and cleared off the map) if they were present there.
      if (!shouldShow(pollingPlaceMarker)) {
        continue;
      }
      currSet.add(pollingPlaceMarker.id);
    }
    var prevSet = new Set.from(_markers.keys);
    var removeSet = prevSet.difference(currSet);
    for (var id in removeSet) {
      var marker = _markers.remove(id);
      marker.map = null;
    }
  }

  updatePollingPlaces(PollingPlacePayload pollingPlacePayload) {
    clearPollingPlaces(pollingPlacePayload);
    // TODO: consider for new polling places API, we receive all polling places, not limited to the viewport
    // so clipping to viewport will give the client a lot less to deal with.
    for (var pollingPlaceMarker in pollingPlacePayload.pollingPlaces) {
      var id = pollingPlaceMarker.id;
      // The clear function determined that the marker with this ID can stay on the map
      // so we skip re-adding it.
      if (_markers.containsKey(id)) {
        continue;
      }
      // Skip adding markers that are meant for higher zoom levels.
      if (!shouldShow(pollingPlaceMarker)) {
        continue;
      }
      var options = new MarkerOptions()..position = pollingPlaceMarker.location;
      if (pollingPlaceMarker.isGroup) {
        options.title = _messages.click_to_zoom_in();
        options.zIndex = Marker.MAX_ZINDEX + 1;
        var count = pollingPlaceMarker.data["count"];
        var dst = '_100_plus.';
        int markerSize = 72;
        if (count < 3) {
          dst = '.';
          markerSize = 48;
        } else if (count < 5) {
          dst = '_3_plus.';
          markerSize = 48;
        } else if (count < 10) {
          dst = '_5_plus.';
          markerSize = 48;
        } else if (count < 25) {
          dst = '_10_plus.';
          markerSize = 53;
        } else if (count < 50) {
          dst = '_25_plus.';
          markerSize = 58;
        } else if (count < 100) {
          dst = '_50_plus.';
          markerSize = 63;
        }
        options.icon = new Icon()
          ..url = _pollingPlaceIconUrl.replaceFirst('.', dst)
          ..scaledSize = new Size(markerSize, markerSize);
      } else {
        options.title = pollingPlaceMarker.data["PremisesName"];
        options.icon = new Icon()
          ..url = _pollingPlaceIconUrl
          ..scaledSize = new Size(48, 48);
      }
      var marker = new Marker(options);
      marker.map = _map;
      _markers[id] = marker;
      if (pollingPlaceMarker.isGroup) {
        marker.onClick.listen((event) {
          // Zoom in.
          var targetZoom = _map.zoom + 1;
          if (pollingPlaceMarker.minZoom != 0) {
            targetZoom = pollingPlaceMarker.minZoom + 1;
          }
          // Center to cluster location.
          var targetCenter = marker.position;
          // Try selecting the electorate for the given cluster.
          var targetElectorate =
              _pageStateService.currentPageState.selectedElectorate;
          var electorateName = pollingPlaceMarker.data["DivisionName"];
          if (electorateName != null &&
              electorateName != "" &&
              electorateName.toLowerCase() != "unknown") {
            targetElectorate = electorateName.toLowerCase();
          }
          _pageStateService.setMapViewportAndElectorate(
              targetCenter, targetZoom, targetElectorate);
          // blank any visible tooltip.
          _placeTooltipService.clearInfoWindow();
        });
        continue;
      }
      marker.onClick.listen((event) {
        _placeTooltipService.showInfoWindow(pollingPlaceMarker);
      });
    }
    _placeTooltipService.markers = _markers;
  }

  clearElectorateLabels(LabelPayload labelPayload) {
    // Calculate the "removeSet" - the set of labels we need to remove from the map.
    var removeSet;
    // If we're zoomed in past the minimum for labels, and the zoom bucket hasn't changed,
    // keep the existing labels on the map by making the remove set the difference between
    // previous and current (via pointDataPayload) sets.
    if (_map.zoom >= minZoomForLabels &&
        _zoomBucketPointData == labelPayload.zoomBucket) {
      var currSet = new Set();
      for (var electorateLabel in labelPayload.electorateLabels) {
        currSet.add(electorateLabel.id);
      }
      var prevSet = new Set.from(_labels.keys);
      removeSet = prevSet.difference(currSet);
    } else {
      // Otherwise remove all labels.
      removeSet = new Set.from(_labels.keys);
    }
    for (var id in removeSet) {
      List<Marker> labelList = _labels.remove(id);
      for (var label in labelList) {
        label.map = null;
      }
    }
  }

  // Firefox and Opera don't like '#' so color description avoids hexadecimal notation.
  static const electorateLabelTextLight =
      '<text x="150" y="20" fill="white" fill-opacity="1" stroke="rgb(38,50,56)" stroke-opacity="0.8" stroke-width="1px" ' +
          'text-anchor="middle" letter-spacing="1.3px" ' +
          'font-family="Roboto,Helvetica,Arial,sans-serif" font-size="22" font-weight="600" >';

  static const electorateLabelTextDark =
      '<text x="150" y="20" fill="black" fill-opacity="1" stroke="white" stroke-opacity="0.8" stroke-width="1px" ' +
          'text-anchor="middle" letter-spacing="1.3px" ' +
          'font-family="Roboto,Helvetica,Arial,sans-serif" font-size="22" font-weight="600" >';

  static const electorateLabelSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 30" width="300" height="30" >';

  static const electorateLabelSvgEnd = '</text></svg>';

  static const minZoomForLabels = 5;

  updateElectorateLabels(LabelPayload labelPayload) {
    clearElectorateLabels(labelPayload);
    _zoomBucketPointData = labelPayload.zoomBucket;
    if (_map.zoom < minZoomForLabels) {
      return;
    }
    for (var electorateLabel in labelPayload.electorateLabels) {
      var id = electorateLabel.id;
      if (_labels.containsKey(id)) {
        continue;
      }
      var electorateLabelText = electorateLabelTextDark;
      var color = _electorateColor[id];
      // Only switch to light text if we are at low zoom level (lower than the thershold for low opacity)
      // AND there is some (non-empty) electorate color.
      if (_map.zoom < minZoomForLowOpacity && color != null) {
        electorateLabelText = electorateLabelTextLight;
      }
      List<Marker> labelList = new List();
      for (var location in electorateLabel.locations) {
        var svg = "data:image/svg+xml;charset=UTF-8," +
            Uri.encodeFull(
                "${electorateLabelSvg} ${electorateLabelText} ${electorateLabel.name} ${electorateLabelSvgEnd}");
        var icon = new Icon()
          ..anchor = new Point(150, 20)
          ..scaledSize = new Size(300, 30)
          ..size = new Size(300, 30)
          ..url = svg;
        var options = new MarkerOptions()
          ..position = location
          ..clickable = false
          ..title = electorateLabel.name
          ..optimized = false
          ..zIndex = Marker.MAX_ZINDEX + 2
          ..icon = icon;
        var label = new Marker(options);
        label.map = _map;
        labelList.add(label);
      }
      _labels[id] = labelList;
    }
  }
}
