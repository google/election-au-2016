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

import 'package:angular2/angular2.dart' show Component, Input;
import 'package:angular2/src/common/pipes/number_pipe.dart';
import '../i18n/messages.dart';
import '../map/party_alignment.dart';
import '../services/election_firebase_service.dart';

@Component(
    selector: 'partylist',
    templateUrl: 'party_list_component.html',
    pipes: const [DecimalPipe, PercentPipe])
class PartyListComponent {
  final Messages messages;
  String get msg_party => messages.party();
  String get msg_seats => messages.seats();

  List<PartyColor> parties;
  bool showUnelectedParties;
  bool _liveResults;

  @Input()
  set liveResults(bool live) {
    showUnelectedParties = !live;
    _liveResults = live;
  }

  bool get liveResults => this._liveResults;

  Iterable<PartyColor> get displayParties {
    if (showUnelectedParties) {
      return parties;
    }
    return parties.where((pc) => pc.p.seatsInNation > 0);
  }

  @Input()
  set partyMap(Map<String, Party> partyMap) {
    parties = new List<PartyColor>();
    if (parties == null) {
      return;
    }
    try {
      List<String> keys = new List.from(partyMap.keys);
      keys.sort((a, b) {
        var ap = partyMap[a];
        var bp = partyMap[b];
        num c = bp.seatsInNation.compareTo(ap.seatsInNation);
        if (c != 0) {
          return c;
        }
        return ap.name.compareTo(bp.name);
      });
      for (var key in keys) {
        var p = partyMap[key];
        if (!p.active) {
          continue;
        }
        parties.add(new PartyColor(p, getColorForParty(p, partyMap)));
      }
    } catch (exception, stacktrace) {
      print("Couldn't parse parties: $exception");
      print(stacktrace);
    }
  }

  toggleUnelected() => showUnelectedParties = !showUnelectedParties;

  String getColorForParty(Party p, Map<String, Party> allParties) {
    if (p.seatsInNation >= 3) {
      return p.color;
    }
    if (PartyAlignment.relatedPartiesHaveMoreThan3SeatsTotal(
        p.id, allParties)) {
      return p.color;
    }
    // Default
    return "#bdbdbd";
  }

  String get moreOrLess =>
      showUnelectedParties ? messages.show_less() : messages.show_more();

  PartyListComponent(this.messages) {}
}

class PartyColor {
  PartyColor(this.p, this.color);
  final Party p;
  final String color;
}
