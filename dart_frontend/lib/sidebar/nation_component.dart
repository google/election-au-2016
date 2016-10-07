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

import 'package:angular2/angular2.dart' show Component, DatePipe, Input;
import '../i18n/messages.dart';
import '../services/election_firebase_service.dart';
import 'halfdonut_component.dart';
import 'party_list_component.dart';

@Component(
    selector: 'nation',
    templateUrl: 'nation_component.html',
    directives: const [
      HalfDonutComponent,
      PartyListComponent,
    ])
class NationComponent {
  final Messages messages;

  // TODO(dazza): What happens timezone wise.
  static DateTime election_date = DateTime.parse("2016-07-02 18:00:00");

  static const DatePipe _datePipe = const DatePipe();

  String get msg_update_info {
    if (nation == null) {
      return "";
    }
    if (nation.historic) {
      return messages.election_results_will_be_updated_from(
          _datePipe.transform(election_date),
          _datePipe.transform(election_date, 'shortTime'));
    } else {
      DateTime dateTime = DateTime.parse(nation.updated);
      return messages.last_updated(_datePipe.transform(dateTime),
          _datePipe.transform(dateTime, 'shortTime'));
    }
  }

  String get msg_nation_title {
    if (nation == null) {
      return "";
    }
    if (nation.historic) {
      return messages.historical_results_title();
    } else {
      return messages.australian_election_results();
    }
  }

  @Input()
  Nation nation;

  NationComponent(this.messages);
}
