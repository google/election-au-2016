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
import '../i18n/messages.dart';
import '../services/electorate_spatial_service.dart';
import '../services/election_firebase_service.dart';

@Component(
    selector: 'pollingplacedetails',
    templateUrl: 'polling_place_details_component.html')
class PollingPlaceDetailsComponent implements OnInit, OnDestroy {
  Messages _messages;

  String name;
  String address;
  bool isAccessible;

  String get msg_accessible => _messages.accessible();
  String get msg_sausage_sizzle => _messages.sausage_sizzle();
  String get msg_cake_stall => _messages.cake_stall();
  String get msg_more_details => _messages.more_details();

  @Input()
  PollingPlaceInfo place;

  @Input()
  Election election;

  String moreInformationUrl;

  bool hasSausage;
  bool hasCake;
  num stallid = 0;
  StreamSubscription pollingPlaceFoodStreamSubscription;

  PollingPlaceDetailsComponent(this._messages);

  ngOnInit() {
    name = place.premisesName;
    address = place.address.toString();
    isAccessible = place.wheelchairAccess;
    stallid = 0;
    if (election != null) {
      pollingPlaceFoodStreamSubscription = election
          .pollingPlaceFoodStream(place.pollingPlaceId)
          .listen((PollingPlaceFood food) {
        hasSausage = food.sausages;
        hasCake = food.cake;
        stallid = food.stallid;
      });
    }
  }

  ngOnDestroy() {
    pollingPlaceFoodStreamSubscription.cancel();
  }
}
