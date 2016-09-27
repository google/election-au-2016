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

import '../services/election_firebase_service.dart';

class PartyAlignment {
  static const List<String> liberals = const ['LP', 'LNP', 'CLP'];
  static const List<String> _coalition = const ['LP', 'LNP', 'NP', 'CLP'];
  static const String coalitionSpecialCode = "COALITION_SPECIAL_CODE";

  static bool shouldAlignRight(String partyCode) {
    return partyCode == coalitionSpecialCode || _coalition.contains(partyCode);
  }

  static bool isSomeKindOfLiberalParty(String partyCode) {
    return liberals.contains(partyCode);
  }

  static bool relatedPartiesHaveMoreThan3SeatsTotal(
      String partyCode, Map<String, Party> parties) {
    return _coalition.contains(partyCode) &&
        coaltionHaveMoreThan3SeatsTotal(parties);
  }

  static bool coaltionHaveMoreThan3SeatsTotal(Map<String, Party> parties) {
    int coalitionSeats = _coalition.fold(0, (dynamic count, String partyID) {
      Party p = parties[partyID];
      if (p == null) {
        return count;
      }
      return count + p.seatsInNation;
    });

    return coalitionSeats >= 3;
  }
}
