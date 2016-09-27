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
import '../i18n/messages.dart';

@Component(selector: 'search-not-found', templateUrl: 'search_not_found.html')
class SearchNotFoundComponent {
  final Messages _messages;

  @Input()
  String searchQuery;

  String get msg_we_could_not_find => _messages.we_could_not_find(searchQuery);
  String get msg_make_sure_your_search => _messages.make_sure_your_search();
  String get msg_more_google_search_results =>
      _messages.more_google_search_results(searchQuery);

  SearchNotFoundComponent(this._messages);
}
