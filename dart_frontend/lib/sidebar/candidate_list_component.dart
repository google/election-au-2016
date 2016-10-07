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
import 'package:angular2/angular2.dart' show Component, Input;
import 'package:angular2/src/common/pipes/number_pipe.dart';
import '../i18n/messages.dart';
import '../services/election_firebase_service.dart';
import 'candidate_image_component.dart';

@Component(
    selector: 'candidatelist',
    templateUrl: 'candidate_list_component.html',
    directives: const [
      CandidateImageComponent,
    ],
    pipes: const [
      DecimalPipe,
      PercentPipe
    ])
class CandidateListComponent {
  List<CandidateParty> candidateParties;

  @Input()
  bool liveResults;

  final Messages messages;
  String get msg_candidate => messages.candidate();
  String get msg_votes => messages.votes();

  String _electorateName;

  @Input()
  set electorate(Electorate electorate) {
    if (electorate == null) {
      candidateParties = null;
      _electorateName = null;
      return;
    }

    _electorateName = electorate.name;

    try {
      this.candidateParties =
          new List.from(electorate.candidates.values.map((c) {
        var p = electorate.parties[c.party];
        var bkg = _makeBackgroundImage(c, p);
        return new CandidateParty(c, p, bkg);
      }));

      // Sort by votes. If votes are equal, sort by ballot paper position.
      this.candidateParties.sort((a, b) {
        // Use descending for votes
        num c = b.candidate.votesInElectorate.total
            .compareTo(a.candidate.votesInElectorate.total);
        if (c != 0) {
          return c;
        }
        // Use ascending for ballot position
        return a.candidate.ballotPosition.compareTo(b.candidate.ballotPosition);
      });
    } catch (exception, stacktrace) {
      print("Couldn't prepare candidate list: $exception");
      print(stacktrace);
    }
  }

  // Makes a background image that fills up from the left to a % equivalent to the percentage
  // of votes a candidate got. Uses the party color.
  String _makeBackgroundImage(Candidate candidate, Party party) {
    if (!liveResults) {
      return null;
    }

    var cutoff = candidate.votesInElectorate.percentage;
    var color = _hexToRgba(party.color, 0.2);

    return 'linear-gradient('
        'to right,'
        '${color} 0%, '
        '${color} ${cutoff}%, '
        'transparent ${cutoff}%)';
  }

  // Converts a hex-valued color to rgb, adds an opacity value and returns a CSS rgba() clause.
  String _hexToRgba(String hex, num opacity) {
    var m = _hexRegex.firstMatch(hex.trim());
    var r = int.parse(m.group(1), radix: 16);
    var g = int.parse(m.group(2), radix: 16);
    var b = int.parse(m.group(3), radix: 16);
    return "rgba($r, $g, $b, $opacity)";
  }

  final RegExp _hexRegex = new RegExp(
      r"^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$",
      caseSensitive: false);

  // TODO(ftamp): Work out a better query string here.
  // Using Candidate Name doesn't provide sensible results for most candidates. Adding
  // "Australian election 2016" works better for not notable candidates, but worse for notable ones.
  searchForCandidate(CandidateParty cp) {
    String query =
        "${cp.candidate.firstName} ${cp.candidate.lastName} ${cp.party.name} ${_electorateName}";
    window.open(
        "https://www.google.com.au/search?q=${Uri.encodeComponent(query)}",
        '_blank');
  }

  CandidateListComponent(this.messages) {}
}

class CandidateParty {
  final Candidate candidate;
  final Party party;
  final String backgroundImage;

  CandidateParty(this.candidate, this.party, this.backgroundImage);
}
