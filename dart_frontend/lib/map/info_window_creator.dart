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
import 'package:google_maps/google_maps.dart';
import '../i18n/messages.dart';
import '../map/map_utils.dart' as mapUtils;
import '../map/open_hours.dart';
import '../services/election_firebase_service.dart';
import '../services/electorate_spatial_service.dart';

@Injectable()
class InfoWindowCreator {
  final Messages _messages;

  @Input()
  Election election;

  InfoWindowCreator(Messages this._messages);

  String get msg_opening_hours {
    return OpenHours.formatOpenHours(_messages);
  }

  Future<InfoWindow> create(PollingPlaceMarker pollingPlaceMarker) async {
    PollingPlaceFood placeFood = null;
    if (election != null) {
      placeFood = await election
          .pollingPlaceFoodStream(pollingPlaceMarker.placeInfo.pollingPlaceId)
          .first;
    }

    InfoWindowOptions options = new InfoWindowOptions();
    var name = pollingPlaceMarker.placeInfo.premisesName;
    var address = pollingPlaceMarker.placeInfo.address.toString();
    var msg_accessible = _messages.accessible();
    var msg_sausage_sizzle = _messages.sausage_sizzle();
    var msg_cake_stall = _messages.cake_stall();
    var msg_more_details = _messages.more_details();
    bool isAccessible = pollingPlaceMarker.placeInfo.wheelchairAccess;
    bool hasSausageSizzle = placeFood != null && placeFood.sausages;
    bool hasCakeStall = placeFood != null && placeFood.cake;
    num stallid = 0;
    if (placeFood != null) {
      stallid = placeFood.stallid;
    }

    var msg_directions = _messages.directions();
    var url = mapUtils.googleMapsSearchUrlForPlace(pollingPlaceMarker);

    StringBuffer buffer = new StringBuffer();
    buffer.writeln("""
    <div class="placepopup">
      <pollingplacedetails class="hovercard flex-grow">
        <div class="place-name">${name}</div>
        <div class="place-address">${address}</div>
        <div class="place-features">""");
    if (isAccessible) {
      buffer.write("""
        <div class="feature place-accessible">
          <img class="icon" src="/static/ic_accessible.svg" />
          ${msg_accessible}
        </div>
        """);
    }

    if (hasSausageSizzle) {
      buffer.write("""
        <div class="feature place-accessible">
          <img class="icon" src="/static/ic_sausage.svg" />
          ${msg_sausage_sizzle}
        </div>
        """);
    }

    if (hasCakeStall) {
      buffer.write("""
        <div class="feature place-accessible">
          <img class="icon" src="/static/ic_cake.svg" />
          ${msg_cake_stall}
        </div>
        """);
    }

    if (stallid != 0) {
      buffer.write("""
        <div class="feature place-attribution">
          <a target="_blank" href="http://www.electionsausagesizzle.com.au/webpages/electionv2/singleboothmap.aspx?stallid=${stallid}">
            ${msg_more_details}
          </a>
        </div>
        """);
    }

    buffer.write("""
        </div>
        <div class="opening-hours">${msg_opening_hours}</div>
      </pollingplacedetails>
      <a class="directions clickable" target="_blank" href="${url}">
        <img class="directions-icon" src="/static/ic_directions.svg" />
        <div class="directions-label">
          ${msg_directions}
        </div>
      </div>
    </div>
    """);
    options.content = buffer.toString();
    InfoWindow window = new InfoWindow(options);
    return window;
  }
}
