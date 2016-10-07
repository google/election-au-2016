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

import 'package:angular2/angular2.dart' show Component, Input, JsonPipe;
import 'package:angular2/src/common/pipes/number_pipe.dart';
import '../i18n/messages.dart';
import '../map/party_alignment.dart';
import '../services/election_firebase_service.dart';
import 'candidate_image_component.dart';

@Component(
    selector: 'twoparty',
    templateUrl: 'two_party_component.html',
    directives: const [
      CandidateImageComponent,
    ],
    pipes: const [
      PercentPipe,
      JsonPipe
    ])
class TwoPartyComponent {
  static const DecimalPipe _decimalPipe = const DecimalPipe();

  CandidateParty left;
  CandidateParty right;
  // TODO(ftamp): check this color, it was added unsupervised.
  static const String _defaultSeatColor = "#E1E1E1";
  // Color to use for the seat icon.
  String seatColor;

  final Messages _messages;

  String _votesForCandidate(CandidateParty cp) {
    num voteCount =
        cp == null ? 0 : cp.candidate.preferenceVotesInElectorate.total;
    return _messages.num_votes(_decimalPipe.transform(voteCount));
  }

  String get msg_num_votes_left {
    return _votesForCandidate(left);
  }

  String get msg_num_votes_right {
    return _votesForCandidate(right);
  }

  @Input()
  set electorate(Electorate electorate) {
    if (electorate == null ||
        electorate.preferredCandidates[0] == null ||
        electorate.preferredCandidates[1] == null) {
      left = null;
      right = null;
      seatColor = _defaultSeatColor;
      return;
    }
    try {
      List<CandidateParty> candidateParties =
          new List.from(electorate.preferredCandidates.map((c) {
        var p = electorate.parties[c.party];
        return new CandidateParty(c, p);
      }));

      //
      Party winner = electorate.winningParty;
      if (winner == null) {
        seatColor = _defaultSeatColor;
      } else {
        seatColor = winner.color;
      }

// TODO fix seat icon

      // TODO check how we want to assign candidates to the left and right here.
      // e.g. Do we want to left-align Greens vs. Labor?
      // If the candidate on the left should be right-aligned, align them to the right.
      if (PartyAlignment.shouldAlignRight(candidateParties[1].party.id)) {
        left = candidateParties[0];
        right = candidateParties[1];
      } else {
        left = candidateParties[1];
        right = candidateParties[0];
      }
    } catch (exception, stacktrace) {
      print("Couldn't prepare candidate list: $exception");
      print(stacktrace);
    }
  }

  TwoPartyComponent(this._messages);
}

class CandidateParty {
  final Candidate candidate;
  final Party party;

  const CandidateParty(this.candidate, this.party);
}
