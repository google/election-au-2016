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
import 'package:angular2/angular2.dart' show Component;
import '../i18n/messages.dart';
import '../services/search_service.dart';
import 'search_not_found.dart';

@Component(
    selector: 'search',
    templateUrl: 'search_component.html',
    directives: const [SearchNotFoundComponent])
class SearchComponent {
  final SearchService _searchService;
  final Messages _messages;

  String get msg_search_placeholder =>
      _messages.search_address_suburb_or_electorate();
  // TODO, when we support searching for candidates:
  // _messages.search_address_suburb_electorate_or_candidate();

  Timer keypressDelay = null;
  bool idle = true;

  String _searchQuery = "";

  String get searchQuery => _searchQuery;

  void set searchQuery(String query) {
    _searchQuery = query;
    _searchService.search(query).then((List<SearchResult> searchResults) {
      _searchResults = searchResults;
    });
    idle = false;
    if (keypressDelay != null) {
      keypressDelay.cancel();
    }
    keypressDelay = new Timer(new Duration(milliseconds: 500), () {
      idle = true;
    });
  }

  List<SearchResult> _searchResults;
  List<SearchResult> get searchResults => _searchResults;

  resetClicked(event) {
    _searchQuery = "";
    _searchResults.clear();
  }

  searchClicked(event) {
    // TODO: refire search?
  }

  onEnter() {
    if (searchResults.length == 0) {
      return;
    }
    selected(searchResults[0]);
  }

  selected(SearchResult searchResult) {
    searchResult.selected();
    new Timer(new Duration(milliseconds: 100), () {
      _searchQuery = "";
      _searchResults.clear();
    });
  }

  keypressSelected(dynamic event, SearchResult result) {
    var code = event.which;
    // Enter or Space
    if ((code == 13) || (code == 32)) {
      selected(result);
      event.preventDefault();
    }
  }

  bool get hasResults => searchResults != null && searchResults.length > 0;

  bool get hasZeroResults =>
      searchResults != null &&
      searchResults.length == 0 &&
      searchQuery.length > 2 &&
      idle;

  SearchComponent(this._searchService, this._messages);
}
