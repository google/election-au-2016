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

import 'package:angular2/angular2.dart';
import '../i18n/messages.dart';

class OpenHours {
  static final openDate = new DateTime(2016, 07, 02, 8, 00);
  static final closeDate = new DateTime(2016, 07, 02, 18, 00);
  static const DatePipe _datePipe = const DatePipe();

  static String formatOpenHours(Messages messages) {
    return messages.open_on(
        _datePipe.transform(openDate, 'mediumDate'),
        _datePipe.transform(openDate, 'shortTime'),
        _datePipe.transform(closeDate, 'shortTime'));
  }
}
