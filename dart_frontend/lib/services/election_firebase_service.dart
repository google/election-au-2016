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
import 'dart:convert';
import 'dart:html' show querySelector;
import 'package:angular2/angular2.dart' show Injectable;
import 'package:firebase3/firebase.dart' as firebase;
import '../configuration.dart';

class VoteSummary {
  final num percentage;
  final num total;
  VoteSummary(this.percentage, this.total);
}

VoteSummary _parseVoteSummary(Map<String, dynamic> value) {
  num percentage = value['Percentage'];
  if (percentage == null) {
    percentage = 0;
  }
  num total = value['Total'];
  return new VoteSummary(percentage, total);
}

const List<String> _coalitionParties = const ['LP', 'LNP', 'NP', 'CLP'];

class Party {
  final String color;
  final String id;
  final String name;
  final String leader;
  final num seatsInNation;
  final VoteSummary votesInNation;
  final bool active;
  Party(this.color, this.id, this.name, this.seatsInNation, this.votesInNation,
      this.leader, this.active);
  String toString() => 'Party $color $id $name $seatsInNation\n$votesInNation';
}

Party _parseParty(Map<String, dynamic> value) {
  String color = value['Color'];
  String id = value['ID'];
  String name = value['Name'];
  String leader = value['Leader'];
  var active = value['Active'];
  num seatsInNation = value['SeatsInNation'];
  var votesInNation = _parseVoteSummary(value['VotesInNation']);
  return new Party(
      color, id, name, seatsInNation, votesInNation, leader, active);
}

class Nation {
  final num enrolment;
  final Map<String, Party> parties;
  final String phase;
  final String updated;
  final Map<String, String> winningPartyByElectorate;
  final Map<String, String> leadingPartyByElectorate;
  final bool historic;
  final bool showPolling;
  Nation(
      this.enrolment,
      this.parties,
      this.phase,
      this.updated,
      this.winningPartyByElectorate,
      this.leadingPartyByElectorate,
      this.historic,
      this.showPolling);
  String toString() =>
      'Nation $enrolment $phase $updated\n$winningPartyByElectorate';

  Party get coalitionParty {
    num seats = 0;
    num percentage = 0;
    num total = 0;
    for (String code in _coalitionParties) {
      seats += parties[code].seatsInNation;
      percentage += parties[code].votesInNation.percentage;
      total += parties[code].votesInNation.total;
    }
    return new Party(parties['LP'].color, 'Coalition', 'Coalition', seats,
        new VoteSummary(percentage, total), parties['LP'].leader, true);
  }

  Party get winningParty {
    num electedSeats = 0;
    Party first = coalitionParty;
    Party second;
    for (String key in parties.keys) {
      electedSeats += parties[key].seatsInNation;
      if (first == null || first.seatsInNation < parties[key].seatsInNation) {
        second = first;
        first = parties[key];
      } else if (second == null ||
          second.seatsInNation < parties[key].seatsInNation) {
        second = parties[key];
      }
    }
    num spareSeats = 150 - electedSeats;
    if (first.seatsInNation > second.seatsInNation + spareSeats) {
      return first;
    }
    return null;
  }
}

Nation _parseNation(dynamic value) {
  num enrolment = value['Enrolment'];
  String phase = value['Phase'];
  String updated = value['Updated'];
  var partiesValue = value['Parties'] as Map<String, dynamic>;
  var parties = new Map<String, Party>();
  for (String key in partiesValue.keys) {
    var partyValue = partiesValue[key];
    parties[key] = _parseParty(partyValue);
  }
  var winningPartyByElectorate =
      value['WinningPartyByElectorate'] as Map<String, String>;
  var leadingPartyByElectorate =
      value['LeadingPartyByElectorate'] as Map<String, String>;
  var historic = value['Historic'];
  var showPolling = value['ShowPolling'];
  return new Nation(
      enrolment,
      parties,
      phase,
      updated,
      winningPartyByElectorate,
      leadingPartyByElectorate,
      historic,
      showPolling);
}

class Candidate {
  final num ballotPosition;
  final bool elected;
  final String id;
  final String firstName;
  final String lastName;
  final String initials;
  final String party;
  final String profileUrl;
  final VoteSummary votesInElectorate;
  final VoteSummary preferenceVotesInElectorate;
  Candidate(
      this.ballotPosition,
      this.elected,
      this.id,
      this.firstName,
      this.lastName,
      this.initials,
      this.party,
      this.profileUrl,
      this.votesInElectorate,
      this.preferenceVotesInElectorate);
}

Candidate _parseCandidate(Map<String, dynamic> value) {
  if (value == null) {
    return null;
  }
  num ballotPosition = value['BallotPosition'];
  bool elected = value['Elected'];
  String id = value['ID'];
  String firstName = value['FirstName'];
  String lastName = value['LastName'];
  String initials = value['Initials'];
  String party = value['Party'];
  String profileUrl = value['ProfileURL'];
  var votesInElectorate = _parseVoteSummary(value['VotesInElectorate']);
  var preferenceVotesInElectorate =
      _parseVoteSummary(value['PreferenceVotesInElectorate']);
  return new Candidate(
      ballotPosition,
      elected,
      id,
      firstName,
      lastName,
      initials,
      party,
      profileUrl,
      votesInElectorate,
      preferenceVotesInElectorate);
}

class Electorate {
  final num area;
  final Map<num, Candidate> candidates;
  final num enrolment;
  final String name;
  final Map<String, Party> parties;
  final num pollingPlacesExpected;
  final num pollingPlacesReturned;
  final num tcpPollingPlacesExpected;
  final num tcpPollingPlacesReturned;
  final List<Candidate> preferredCandidates;
  final String winningPartyID;
  Electorate(
      this.area,
      this.candidates,
      this.enrolment,
      this.name,
      this.parties,
      this.pollingPlacesExpected,
      this.pollingPlacesReturned,
      this.tcpPollingPlacesExpected,
      this.tcpPollingPlacesReturned,
      this.preferredCandidates,
      this.winningPartyID);
  String toString() =>
      'Electorate $name $area $enrolment $pollingPlacesExpected $pollingPlacesReturned $preferredCandidates $winningPartyID';

  Party get winningParty {
    if (winningPartyID != "") {
      return parties[winningPartyID];
    }
    return null;
  }
}

Electorate _parseElectorate(Map<String, dynamic> value) {
  num area = value['Area'];
  var candidates = new Map<num, Candidate>();
  var candidatesValue = value['Candidates'] as Map<num, dynamic>;
  if (candidatesValue != null) {
    for (String key in candidatesValue.keys) {
      candidates[key] = _parseCandidate(candidatesValue[key]);
    }
  }
  num enrolment = value['Enrolment'];
  String name = value['Name'];
  var parties = new Map<String, Party>();
  var partiesValue = value['Parties'] as Map<String, dynamic>;
  if (partiesValue != null) {
    for (String key in partiesValue.keys) {
      parties[key] = _parseParty(partiesValue[key]);
    }
  }
  num pollingPlacesExpected = value['PollingPlacesExpected'];
  num pollingPlacesReturned = value['PollingPlacesReturned'];
  num tcpPollingPlacesExpected = value['TCPPollingPlacesExpected'];
  num tcpPollingPlacesReturned = value['TCPPollingPlacesReturned'];
  var preferredCandidates = [
    _parseCandidate(value['FirstCandidatePreferred']),
    _parseCandidate(value['SecondCandidatePreferred'])
  ];
  var winningPartyID = value['WinningParty'];
  return new Electorate(
      area,
      candidates,
      enrolment,
      name,
      parties,
      pollingPlacesExpected,
      pollingPlacesReturned,
      tcpPollingPlacesExpected,
      tcpPollingPlacesReturned,
      preferredCandidates,
      winningPartyID);
}

class PollingPlaceFood {
  final String id;
  final bool sausages;
  final bool cake;
  final num stallid;
  PollingPlaceFood(this.id, this.sausages, this.cake, this.stallid);
}

PollingPlaceFood _parsePollingPlaceFood(Map<String, dynamic> value) {
  String id = value['Id'];
  bool sausages = value['Sausage'];
  bool cake = value['Cake'];
  num stallid = value['StallID'];
  return new PollingPlaceFood(id, sausages, cake, stallid);
}

class Election {
  final String _baseUrl;
  final firebase.Database _database;
  final Nation nation;

  Stream<Electorate> electorateStream(String name) {
    var electorateRef = _database.ref('$_baseUrl-electorate/$name');
    StreamController<Electorate> controller = new StreamController();
    StreamSubscription subscription;
    controller.onListen = () {
      subscription = electorateRef.onValue.listen((firebase.QueryEvent event) {
        var val = event.snapshot.val();
        if (val == null) {
          // Prevent code hanging up waiting on a future that will never arrive.
          controller
              .add(new Electorate(0, {}, 0, 'Unknown', {}, 0, 0, 0, 0, [], ''));
          return;
        }
        var electorate = _parseElectorate(val);
        controller.add(electorate);
      });
    };
    controller.onCancel = () {
      subscription.cancel();
    };
    return controller.stream;
  }

  Stream<PollingPlaceFood> pollingPlaceFoodStream(num id) {
    var pollingPlaceRef = _database.ref('$_baseUrl-pollingplace/$id');
    StreamController<PollingPlaceFood> controller = new StreamController();
    StreamSubscription subscription;
    controller.onListen = () {
      subscription =
          pollingPlaceRef.onValue.listen((firebase.QueryEvent event) {
        var val = event.snapshot.val();
        if (val == null) {
          // Prevent code hanging up waiting on a future that will never arrive.
          controller.add(new PollingPlaceFood('$id', false, false, 0));
          return;
        }
        var pollingPlace = _parsePollingPlaceFood(val);
        controller.add(pollingPlace);
      });
    };
    controller.onCancel = () {
      subscription.cancel();
    };
    return controller.stream;
  }

  Election(this.nation, this._baseUrl, this._database);
  String toString() => 'Election $nation';
}

Election _parseElection(Map<String, dynamic> nationValue, String baseUrl,
    firebase.Database database) {
  Nation nation = _parseNation(nationValue);
  return new Election(nation, baseUrl, database);
}

@Injectable()
class ElectionFirebaseService {
  final Configuration _config;
  bool seenFirstPayload = false;

  StreamController<Election> _controller;

  Stream<Election> get election => _controller.stream;

  void hideLoadingScreen() {
    querySelector("#loading").style.display = "none";
  }

  void showLoadingScreen() {
    querySelector("#loading").style.display = "";
  }

  ElectionFirebaseService(this._config) {
    _controller = new StreamController.broadcast(onListen: () async {
      try {
        var db = firebase
            .initializeApp(
                apiKey: "AIzaSyC6YIckMr6rU1TLrKEnuSGd0bLoeROzvy8",
                databaseURL: _config.firebaseUrl)
            .database();

        var connectedRef = db.ref("/.info/connected");
        connectedRef.onValue.listen((firebase.QueryEvent event) {
          bool connected = event.snapshot.val();
          if (connected) {
            print("Connection established");
            if (seenFirstPayload) {
              hideLoadingScreen();
            }
          } else {
            print("Connection lost");
            showLoadingScreen();
          }
        });

        var electionRef = db.ref('${_config.election}-nation');
        electionRef.onValue.listen((firebase.QueryEvent event) {
          Election election =
              _parseElection(event.snapshot.val(), '${_config.election}', db);
          _controller.add(election);

          hideLoadingScreen();
          seenFirstPayload = true;
        });
      } catch (exception, stacktrace) {
        print("Couldn't parse election: $exception");
        print(stacktrace);
      }
    });
  }
}
