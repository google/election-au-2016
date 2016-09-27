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

import 'dart:html' show window;
import 'package:angular2/angular2.dart' show Component;
import '../configuration.dart';
import '../services/locale_service.dart';
import '../services/page_state_service.dart';

class Language {
  String locale;
  String name;
  bool selected;

  Language(this.locale, this.name, this.selected) {}
}

@Component(selector: 'language', templateUrl: 'language_component.html')
class LanguageComponent {
  final Configuration configuration;
  final PageStateService pageStateService;

  List<Language> languages;

  updateLocale(locale) {
    print("Updating locale to: " + locale);
    pageStateService.selectedHl = locale;
    window.location.reload();
  }

  LanguageComponent(
      this.configuration, this.pageStateService, LocaleService localeService) {
    this.languages = [];

    localeService.getCurrent().then((currentLocale) {
      List<Language> list = [];
      this.configuration.locales.forEach((locale, name) =>
          list.add(new Language(locale, name, locale == currentLocale)));
      this.languages = list;
    });
  }
}
