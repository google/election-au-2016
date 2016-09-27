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
import 'dart:html';
import 'package:angular2/angular2.dart' show Injectable;
import 'package:google_maps/google_maps.dart';

enum SideBarState { show, hide }

enum _UpdateStateStyle { push, replace }

class PageState {
  static const BREAKPOINT_MOBILE = "mobile";
  static const BREAKPOINT_DESKTOP = "desktop";

  final LatLng center;
  final num zoom;
  final String breakpoint; // Mobile or Desktop?
  final SideBarState sideBarState;
  final String selectedElectorate;
  final String hl;

  PageState(this.center, this.zoom, this.breakpoint, this.sideBarState,
      this.selectedElectorate, this.hl);
  String toString() =>
      'PageState $center $zoom $breakpoint $sideBarState "$selectedElectorate" $hl';
}

@Injectable()
class PageStateService {
  StreamController<PageState> _controller;
  PageState currentPageState;

  static const DEFAULT_LAT = -26.539284588498052;
  static const DEFAULT_LNG = 131.3141575;
  // Special code that means that the map should choose a zoom level based on viewport.
  static const DEFAULT_ZOOM = 0;
  static const DEFAULT_SIDE_BAR_STATE = SideBarState.show;
  static const DEFAULT_SELECTED_ELECTORATE = null;
  static const DEFAULT_HL = 'en';

  PageStateService() {
    try {
      _controller = new StreamController.broadcast();

      var latLng = new LatLng(DEFAULT_LAT, DEFAULT_LNG);
      var zoom = DEFAULT_ZOOM;
      var sideBarState = DEFAULT_SIDE_BAR_STATE;
      var selectedElectorate = DEFAULT_SELECTED_ELECTORATE;
      var hl = DEFAULT_HL;

      var q = Uri.base.queryParameters;
      if (q.containsKey('center')) {
        var data = q['center'].split(',');
        latLng = new LatLng(num.parse(data[0]), num.parse(data[1]));
      }

      if (q.containsKey('zoom')) {
        zoom = num.parse(q['zoom']);
      }

      String breakpoint = _getBreakpointString();

      if (q.containsKey('sidebar')) {
        sideBarState =
            q['sidebar'] == 'hide' ? SideBarState.hide : SideBarState.show;
      }

      if (q.containsKey('electorate')) {
        selectedElectorate = q['electorate'];
      }

      if (q.containsKey('hl')) {
        hl = q['hl'];
      }

      currentPageState = new PageState(
          latLng, zoom, breakpoint, sideBarState, selectedElectorate, hl);
      // Hold this notification until after everything is wired up.
      new Timer(new Duration(milliseconds: 1), () {
        _controller.add(currentPageState);
      });

      window.onPopState.listen((popStateEvent) {
        if (popStateEvent.state != null) {
          var state = popStateEvent.state;
          currentPageState = new PageState(
              new LatLng(state['center']['lat'], state['center']['lng']),
              state['zoom'],
              null,
              state['sideBarState'] == 'show'
                  ? SideBarState.show
                  : SideBarState.hide,
              state['selectedElectorate'],
              state['hl']);
          _controller.add(currentPageState);
        }
      });

      window.onResize.listen((resizeEvent) {
        _setBreakpoint(_getBreakpointString());
      });
    } catch (exception, stacktrace) {
      print(exception);
      print(stacktrace);
    }
  }

  Stream<PageState> get pageState => _controller.stream;

  void _updatedState(_UpdateStateStyle style) {
    var data = {
      'center': {
        'lat': currentPageState.center.lat,
        'lng': currentPageState.center.lng
      },
      'zoom': currentPageState.zoom,
      'sideBarState':
          currentPageState.sideBarState == SideBarState.show ? 'show' : 'hide',
      'selectedElectorate': currentPageState.selectedElectorate,
      'hl': currentPageState.hl,
    };

    var updatedUrl = '?center=${currentPageState.center.toUrlValue(6)}';
    if (currentPageState.zoom != DEFAULT_ZOOM) {
      updatedUrl += '&zoom=${currentPageState.zoom}';
    }
    if (currentPageState.sideBarState != DEFAULT_SIDE_BAR_STATE) {
      updatedUrl += '&sidebar=' +
          '${currentPageState.sideBarState == SideBarState.show ? "show" : "hide"}';
    }
    if (currentPageState.selectedElectorate != DEFAULT_SELECTED_ELECTORATE) {
      updatedUrl += '&electorate=${currentPageState.selectedElectorate}';
    }
    if (currentPageState.hl != DEFAULT_HL) {
      updatedUrl += '&hl=${currentPageState.hl}';
    }

    switch (style) {
      case _UpdateStateStyle.push:
        window.history.pushState(data, 'Page', updatedUrl);
        break;
      case _UpdateStateStyle.replace:
        window.history.replaceState(data, 'Page', updatedUrl);
        break;
      default:
        print("style is null in PageStateService");
    }
  }

  void setMapViewport(LatLng center, num zoom) {
    currentPageState = new PageState(
        center,
        zoom,
        currentPageState.breakpoint,
        currentPageState.sideBarState,
        currentPageState.selectedElectorate,
        currentPageState.hl);
    _updatedState(_UpdateStateStyle.replace);
    _controller.add(currentPageState);
  }

  void setMapViewportAndElectorate(
      LatLng center, num zoom, String selectedElectorate) {
    currentPageState = new PageState(center, zoom, currentPageState.breakpoint,
        currentPageState.sideBarState, selectedElectorate, currentPageState.hl);
    _updatedState(_UpdateStateStyle.push);
    _controller.add(currentPageState);
  }

  String _getBreakpointString() {
    String breakpoint = document.body
        .getComputedStyle(':after')
        .content
        .replaceAll('"', '')
        .replaceAll("'", '');
    return breakpoint;
  }

  void _setBreakpoint(String breakpoint) {
    currentPageState = new PageState(
        currentPageState.center,
        currentPageState.zoom,
        breakpoint,
        currentPageState.sideBarState,
        currentPageState.selectedElectorate,
        currentPageState.hl);
    _controller.add(currentPageState);
  }

  void setNationView() {
    currentPageState = new PageState(
        new LatLng(DEFAULT_LAT, DEFAULT_LNG),
        DEFAULT_ZOOM,
        currentPageState.breakpoint,
        currentPageState.sideBarState,
        null,
        currentPageState.hl);
    _updatedState(_UpdateStateStyle.push);
    _controller.add(currentPageState);
  }

  void set sideBarState(SideBarState sideBarState) {
    currentPageState = new PageState(
        currentPageState.center,
        currentPageState.zoom,
        currentPageState.breakpoint,
        sideBarState,
        currentPageState.selectedElectorate,
        currentPageState.hl);
    _updatedState(_UpdateStateStyle.push);
    _controller.add(currentPageState);
  }

  void set selectedElectorate(String selectedElectorate) {
    currentPageState = new PageState(
        currentPageState.center,
        currentPageState.zoom,
        currentPageState.breakpoint,
        currentPageState.sideBarState,
        selectedElectorate,
        currentPageState.hl);
    _updatedState(_UpdateStateStyle.push);
    _controller.add(currentPageState);
  }

  void set selectedHl(String hl) {
    currentPageState = new PageState(
        currentPageState.center,
        currentPageState.zoom,
        currentPageState.breakpoint,
        currentPageState.sideBarState,
        currentPageState.selectedElectorate,
        hl);
    _updatedState(_UpdateStateStyle.push);
  }
}
