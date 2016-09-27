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
import 'dart:html' show window;
import 'package:angular2/angular2.dart' show Injectable;
import 'package:angular2/src/common/pipes/number_pipe.dart' as numberPipe;
import 'package:angular2/src/common/pipes/date_pipe.dart' as datePipe;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_browser.dart';
import '../configuration.dart';
import '../i18n/messages_all.dart';
import 'page_state_service.dart';

@Injectable()
class LocaleService {
  final Configuration configuration;

  Future<String> getCurrent() async {
    String hl = "en";
    if (!configuration.languages_enabled) {
      return hl;
    }

    // ?hl= trumps detection.
    String explicitHl = Uri.parse(window.location.href).queryParameters['hl'];
    if (explicitHl != null) {
      hl = explicitHl;
    } else {
      await findSystemLocale().then((systemLocale) {
        hl = systemLocale;
      });
    }
    hl = Intl.verifiedLocale(
        hl, (locale) => configuration.locales.containsKey(locale),
        onFailure: (badLocale) => "en");
    return hl;
  }

  LocaleService(this.configuration, PageStateService pageStateService) {
    getCurrent().then((current) {
      // Trigger a page reload if needed.
      String explicitHl = Uri.parse(window.location.href).queryParameters['hl'];
      if (explicitHl == "" && current != "en") {
        pageStateService.selectedHl = current;
        window.location.reload();
      }

      // Explicitly set the locale for the various Angular pipes.
      numberPipe.defaultLocale = current;
      datePipe.defaultLocale = current;
      initializeDateFormatting(current, null);

      initializeMessages(current);
      Intl.defaultLocale = current;
      print("Locale: " + current);
    });
  }
}
