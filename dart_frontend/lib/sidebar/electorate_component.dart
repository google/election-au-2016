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

import 'dart:html' show querySelector;
import 'package:angular2/angular2.dart'
    show Component, DatePipe, Input, DecimalPipe, PercentPipe;
import '../i18n/messages.dart';
import '../map/open_hours.dart';
import '../services/election_firebase_service.dart';
import '../services/electorate_spatial_service.dart';
import '../services/page_state_service.dart';
import 'candidate_list_component.dart';
import 'two_party_component.dart';
import 'polling_places_list_component.dart';

@Component(
    selector: 'electorate',
    templateUrl: 'electorate_component.html',
    directives: const [
      CandidateListComponent,
      TwoPartyComponent,
      PollingPlacesListComponent
    ],
    pipes: const [
      DecimalPipe,
      PercentPipe,
      DatePipe
    ])
class ElectorateComponent {
  static const DatePipe _datePipe = const DatePipe();
  static const DecimalPipe _decimalPipe = const DecimalPipe();
  final PageStateService _pageStateService;

  @Input()
  bool liveResults = true;

  Electorate _electorate;
  @Input()
  set electorate(Electorate electorate) {
    if (electorate == _electorate) {
      return;
    }
    _electorate = electorate;
    var pageState = _pageStateService.currentPageState;
    if (_electorate == "" ||
        pageState.breakpoint == PageState.BREAKPOINT_MOBILE) {
      return;
    }
    var sidebarContent = querySelector("#sidebar-content");
    if (sidebarContent != null) {
      sidebarContent.scrollTop = 0;
    }
  }

  Electorate get electorate => _electorate;

  bool get electorateTwoPartyPreferredGuard =>
      _electorate != null &&
      _electorate.preferredCandidates[0] != null &&
      _electorate.preferredCandidates[1] != null;

  @Input()
  List<PollingPlaceMarker> pollingPlaces;

  @Input()
  String lastUpdated;

  @Input()
  Election election;

  final Messages messages;

  String get msg_electorate_results {
    if (_electorate.name == null) {
      return "";
    }
    return messages.electorate_results(_electorate.name);
  }

  String get msg_ballot_paper {
    return messages.ballot_paper();
  }

  String get msg_last_updated {
    DateTime dateTime = DateTime.parse(lastUpdated);
    return messages.last_updated(_datePipe.transform(dateTime),
        _datePipe.transform(dateTime, 'shortTime'));
  }

  String get msg_tcp_polling_stations_counted {
    return messages.polling_stations_counted(
        _decimalPipe.transform(_electorate.tcpPollingPlacesReturned),
        _decimalPipe.transform(_electorate.tcpPollingPlacesExpected));
  }

  String get msg_polling_stations_counted {
    return messages.polling_stations_counted(
        _decimalPipe.transform(_electorate.pollingPlacesReturned),
        _decimalPipe.transform(_electorate.pollingPlacesExpected));
  }

  String get msg_first_preference_count => messages.first_preference_count();

  String get msg_polling_places => messages.polling_places();

  String get msg_polling_places_hours {
    return OpenHours.formatOpenHours(messages);
  }

  String get msg_wont_go_hungry => messages.wont_go_hungry();

  String get msg_live_sausage_data => messages.live_sausage_data();

  ElectorateComponent(this._pageStateService, this.messages);
}
