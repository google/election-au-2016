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

import 'package:angular2/angular2.dart' show Component, DecimalPipe, Input;
import '../i18n/messages.dart';
import '../map/party_alignment.dart';
import '../services/election_firebase_service.dart';

@Component(selector: 'halfdonut', templateUrl: 'halfdonut_component.html')
class HalfDonutComponent {
  static const DecimalPipe _decimalPipe = const DecimalPipe();

  List<DonutSlice> _slices;
  Iterable<DonutSlice> slices;
  int numDeclared;
  Party _other = new Party("#BDBDBD", "ZZZ", "Other", 0, null, "", false);

  final Messages messages;
  String get msg_needed_for_majority =>
      messages.n_needed_for_majority(_decimalPipe.transform(76));
  String get msg_seats_declared => messages.seats_declared();
  String get msg_num_seats => _decimalPipe.transform(numSeats);
  String get msg_num_declared => _decimalPipe.transform(numDeclared);

  static const num numSeats = 150;
  // degrees
  static const num _anglePerSeat = 180 / numSeats;

  @Input()
  set parties(Map<String, Party> inputParties) {
    Map<String, Party> parties = new Map.from(inputParties);
    numDeclared = 0;
    if (parties == null) {
      _slices = null;
      return;
    }
    // Remove anything that looks like a liberal party and then re-add it as a coalition
    if (PartyAlignment.coaltionHaveMoreThan3SeatsTotal(parties)) {
      int seats = 0;
      Party p;
      for (String partyID in PartyAlignment.liberals) {
        p = parties.remove(partyID);
        if (p == null) {
          continue;
        }
        seats += p.seatsInNation;
      }
      parties[PartyAlignment.coalitionSpecialCode] = new Party(p.color,
          PartyAlignment.coalitionSpecialCode, null, seats, null, null, true);
    }
    try {
      List<String> keys = new List.from(parties.keys);
      // Sort parties descending by number of votes.
      keys.sort((a, b) =>
          parties[b].seatsInNation.compareTo(parties[a].seatsInNation));
      // Separate left and right starting angles, right is for lib-nats, left is everyone else.
      var startLeft = 0;
      var startRight = 0;
      _slices = new List<DonutSlice>();
      // Count of seats for "other" parties.
      // Parties get relegated to "Others" if they
      int otherCount = 0;
      for (var key in keys) {
        var p = parties[key];
        if (p.seatsInNation == 0) {
          // All parties processed, we're done.
          break;
        }
        numDeclared += p.seatsInNation;
        if (p.seatsInNation < 3) {
          // Add to the "others" party.
          // Everything from here in will be < 3, so we can just append the "Others" party to the
          // list.
          otherCount += p.seatsInNation;
          continue;
        }
        num angle = p.seatsInNation * _anglePerSeat;
        if (PartyAlignment.shouldAlignRight(p.id)) {
          startRight -= angle;
          _slices.add(new DonutSlice(p, startRight));
        } else {
          startLeft += angle;
          _slices.add(new DonutSlice(p, startLeft));
        }
      }
      if (otherCount > 0) {
        num angle = otherCount * _anglePerSeat;
        startLeft += angle;
        _slices.add(new DonutSlice(_other, startLeft));
      }
    } catch (exception, stacktrace) {
      print("Couldn't parse election: $exception");
      print(stacktrace);
    }
    slices = _slices.reversed;
  }

  HalfDonutComponent(this.messages);
}

class DonutSlice {
  final Party party;
  final String transform;

  DonutSlice(this.party, angle)
      : this.transform = "rotate(${angle + 180}, 120, 150)";
}
