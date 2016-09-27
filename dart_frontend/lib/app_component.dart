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
import 'package:angular2/core.dart';
import 'package:angular2/src/common/pipes.dart';
import 'map/map_component.dart';
import 'map/language_component.dart';
import 'map/info_window_creator.dart';
import 'services/election_firebase_service.dart';
import 'services/electorate_metadata_service.dart';
import 'services/electorate_spatial_service.dart';
import 'services/electorates_prefetch_service.dart';
import 'services/locale_service.dart';
import 'services/page_state_service.dart';
import 'services/place_tooltip_service.dart';
import 'services/polling_place_service.dart';
import 'services/search_service.dart';
import 'services/viewport_service.dart';
import 'services/zoom_buckets_service.dart';
import 'sidebar/electorate_component.dart';
import 'sidebar/nation_component.dart';
import 'sidebar/search_component.dart';
import 'configuration.dart';
import 'i18n/messages.dart';

@Component(
    selector: 'my-app',
    templateUrl: 'app_component.html',
    directives: const [
      ElectorateComponent,
      LanguageComponent,
      MapComponent,
      NationComponent,
      SearchComponent,
    ],
    providers: const [
      Configuration,
      ElectionFirebaseService,
      ElectorateMetadataService,
      ElectorateSpatialService,
      ElectoratesPrefetchService,
      InfoWindowCreator,
      LocaleService,
      PageStateService,
      Messages,
      PollingPlaceService,
      PlaceTooltipService,
      SearchService,
      ViewportService,
      ZoomBucketsService,
    ])
class AppComponent {
  final Configuration _config;
  final Messages _messages;
  final PageStateService _pageStateService;
  final SearchService _searchService;
  final ElectorateSpatialService _electorateSpatialService;
  static const DecimalPipe _decimalPipe = const DecimalPipe();

  String _electorateName;
  Election _election;

  PageState pageState;
  String lastUpdated;
  Nation nation;
  Electorate electorate;
  StreamSubscription<Electorate> _electorateStream;

  ElectorateSpatialPayload electorateSpatialPayload;
  LabelPayload labelPayload;

  PollingPlacePayload _pollingPlacePayload;
  PollingPlacePayload get pollingPlacePayload {
    if (nation == null || !nation.showPolling) {
      return null;
    }
    return _pollingPlacePayload;
  }

  List<PollingPlaceMarker> _placesInElectorate;
  List<PollingPlaceMarker> get placesInElectorate {
    if (nation == null || !nation.showPolling) {
      return const [];
    }
    return _placesInElectorate;
  }

  String get msg_open_external => _messages.open_external();
  String get msg_share_link => _messages.share_link();
  String get msg_embed_map => _messages.embed_map();
  String get msg_close => _messages.close();
  String get msg_copy_link_from_address_bar =>
      _messages.copy_link_from_address_bar();
  String get msg_data_sourced_from_aec {
    return _messages.data_sourced_from(
        r'<a target="_blank" href="http://www.aec.gov.au/">Australian Electoral Commission</a>');
  }

  String get msg_sausage_sizzle_data_provided_by {
    return _messages.sausage_sizzle_data_provided_by(
        r'<a target="_blank" href="http://democracysausage.org/">Democracy Sausage</a>',
        r'<a target="_blank" href="http://www.electionsausagesizzle.com.au/">Snag Votes</a>');
  }

  String get msg_send_feedback => _messages.send_feedback();

  String shareLinkURL;
  String embedMapText;

  @Input()
  set electorateName(String electorateName) {
    if (_electorateName == electorateName) {
      return;
    }
    _electorateName = electorateName;
    _updateElectorate();
  }

  String get electorateName => this._electorateName;

  @Input()
  set election(Election election) {
    if (election != null) {
      _election = election;
      nation = election.nation;
      lastUpdated = nation.updated;
      _electorateSpatialService.showPollingPlaces = nation.showPolling;
      _updateElectorate();
    }
  }

  Election get election => this._election;

  viewNation() {
    _pageStateService.setNationView();
    // Clear the search query from the side bar, and remove the marker from
    // the map.
    _searchService.selectSearchLocation(null, null);
  }

  hideShareAndEmbed() {
    shareLinkURL = null;
    embedMapText = null;
  }

  shareLink() {
    hideShareAndEmbed();
    shareLinkURL = Uri.base.toString();
  }

  embedMap() {
    hideShareAndEmbed();
    embedMapText =
        "<iframe width=\"600px\" height=\"400px\" style=\"border: none;\" src=\"${Uri.base.toString()}&sidebar=hide\"></iframe>";
  }

  bool get languages_enabled => _config.languages_enabled;
  bool get sideBarShow => pageState.sideBarState == SideBarState.show;
  bool get sideBarHide => pageState.sideBarState == SideBarState.hide;

  toggleSidebar() {
    if (sideBarShow) {
      _pageStateService.sideBarState = SideBarState.hide;
    } else {
      _pageStateService.sideBarState = SideBarState.show;
    }
  }

  String get msg_region_name {
    if (electorateName == null) {
      return _messages.australian_house_of_representatives();
    } else if (electorate != null) {
      return _messages.electorate_of(electorate.name);
    } else {
      return "";
    }
  }

  String get msg_region_area {
    var area = 0;
    if (electorate != null) {
      area = electorate.area;
    } else if (electorateName == null) {
      area = 7692024;
    }
    return _messages.electorate_area(_decimalPipe.transform(area));
  }

  String get msg_region_electors {
    var electors = 0;
    if (electorate != null) {
      electors = electorate.enrolment;
    } else if (electorateName == null && nation != null) {
      electors = nation.enrolment;
    }
    return _messages.electors(_decimalPipe.transform(electors));
  }

  Party get winningParty {
    if (electorateName != null) {
      if (electorate != null) {
        return electorate.winningParty;
      }
    } else if (nation != null) {
      return nation.winningParty;
    }
    return null;
  }

  String get color {
    if (winningParty == null) {
      return "#455a64";
    }
    return winningParty.color;
  }

  String get winningName {
    if (winningParty == null) {
      return "Unknown";
    }
    return winningParty.name;
  }

  // Note: this unsubscribes from existing electorate and resubscribes - don't
  // call this unless the electorate has changed.
  _updateElectorate() {
    if (_electorateName == null || _election == null) {
      electorate = null;
      return;
    }

    try {
      if (_electorateStream != null) {
        _electorateStream.cancel();
        _electorateStream = null;
      }
      var stream = _election.electorateStream(_electorateName);
      _electorateStream = stream.listen((data) async {
        this.electorate = data;
      });
    } catch (exception, stacktrace) {
      print("Couldn't parse election: $exception");
      print(stacktrace);
    }
  }

  // This can easily get the wrong result, as the last payload recorded may not reflect the user latest
  // pan/zoom movement (as responses may come out of sync in relation to the order of requests).
  Future _updatePollingPlaces(PollingPlacePayload newPayload) async {
    if (newPayload != null) {
      this._pollingPlacePayload = newPayload;
    }
    if (_electorateName == null || _electorateName == "") {
      _placesInElectorate = new List();
      return;
    }
    // TODO maybe wasteful to fire off a request for a single electorate choice, but this is very cachable so
    // expectation is we won't see many requests fired here unless user stays at low zoom and serially clicks
    // many electorates. Even then, it's probably a reasonable payload.
    var singleElectoratePollingPlacesPayload = await _electorateSpatialService
        .electorateIdsToPollingPlacePayload(_electorateName);
    if (singleElectoratePollingPlacesPayload == null) {
      _placesInElectorate = new List();
      return;
    }
    _placesInElectorate = new List.from(
        singleElectoratePollingPlacesPayload.pollingPlaces
            .where((p) => !p.isGroup),
        growable: false);
  }

  AppComponent(
      this._config,
      ElectionFirebaseService electionFirebaseService,
      LocaleService localService,
      this._messages,
      this._pageStateService,
      this._searchService,
      this._electorateSpatialService) {
    print("firebase: ${_config.firebaseUrl}, election: ${_config.election}");
    electionFirebaseService.election.listen((data) async {
      this.election = data;
    });
    pageState = _pageStateService.currentPageState;
    _pageStateService.pageState.listen((PageState pageState) {
      this.pageState = pageState;
      this.electorateName = pageState.selectedElectorate;
      _updatePollingPlaces(null);
    });
    _electorateSpatialService.electorateSpatialPayload
        .listen((ElectorateSpatialPayload electorateSpatialPayload) {
      // debug:
      // print(electorateSpatialPayload);
      this.electorateSpatialPayload = electorateSpatialPayload;
    });
    _electorateSpatialService.pollingPlacePayload
        .listen((PollingPlacePayload pollingPlacePayload) {
      _updatePollingPlaces(pollingPlacePayload);
    });
    _electorateSpatialService.labelPayload.listen((LabelPayload labelPayload) {
      this.labelPayload = labelPayload;
    });
  }
}
