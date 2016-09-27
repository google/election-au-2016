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
import 'dart:html';
import 'package:angular2/angular2.dart' show Injectable;
import 'package:google_maps/google_maps.dart' show LatLng;
import '../configuration.dart';

class PollingPlace {
  num stateCode;
  String stateAbbreviation;
  String divisionName;
  num divisionId;
  num divisionCode;
  String prettyPrintName;
  num pollingPlaceId;
  String status;
  String premisesName;
  String address1;
  String address2;
  String address3;
  String addressSuburb;
  String addressStateAbbreviation;
  num postcode;
  String advPremisesName;
  String advAddress;
  String advLocality;
  String adviceBoothLocation;
  String adviceGateAccess;
  String entrancesDescription;
  LatLng location;
  num censusCollectionDistrict;
  String wheelchairAccess;
  num ordinaryVoteEstimate;
  num declarationVoteEstimate;
  num numberOrdinaryIssuingOfficers;
  num numberDeclarationIssuingOfficers;

  PollingPlace(dynamic json) {
    stateCode = json['StateCode'];
    stateAbbreviation = json['StateAbbreviation'];
    divisionName = json['DivisionName'];
    divisionId = json['DivisionId'];
    divisionCode = json['DivisionCode'];
    prettyPrintName = json['PrettyPrintName'];
    pollingPlaceId = json['PollingPlaceId'];
    status = json['Status'];
    premisesName = json['PremisesName'];
    address1 = json['Address1'];
    address2 = json['Address2'];
    address3 = json['Address3'];
    addressSuburb = json['AddressSuburb'];
    addressStateAbbreviation = json['AddressStateAbbreviation'];
    postcode = json['Postcode'];
    advPremisesName = json['AdvPremisesName'];
    advAddress = json['AdvAddress'];
    advLocality = json['AdvLocality'];
    adviceBoothLocation = json['AdviceBoothLocation'];
    adviceGateAccess = json['AdviceGateAccess'];
    entrancesDescription = json['EntrancesDescription'];
    location = new LatLng(json['Lat'], json['Lng']);
    censusCollectionDistrict = json['CensusCollectionDistrict'];
    wheelchairAccess = json['WheelchairAccess'];
    ordinaryVoteEstimate = json['OrdinaryVoteEstimate'];
    declarationVoteEstimate = json['DeclarationVoteEstimate'];
    numberOrdinaryIssuingOfficers = json['NumberOrdinaryIssuingOfficers'];
    numberDeclarationIssuingOfficers = json['NumberDeclarationIssuingOfficers'];
  }

  String toString() =>
      'Polling Place $pollingPlaceId $divisionName $prettyPrintName $stateAbbreviation';
}

@Injectable()
class PollingPlaceService {
  final Configuration _config;

  Map<String, PollingPlace> pollingPlaceCache = new Map();

  PollingPlaceService(this._config);

  Future<PollingPlace> get(String pollingPlaceId) async {
    if (!pollingPlaceCache.containsKey(pollingPlaceId)) {
      var json = await HttpRequest
          .getString('${_config.apiBaseUrl}polling_place/$pollingPlaceId');
      pollingPlaceCache[pollingPlaceId] = new PollingPlace(JSON.decode(json));
    }
    return pollingPlaceCache[pollingPlaceId];
  }
}
