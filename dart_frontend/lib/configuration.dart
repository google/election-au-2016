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

import 'package:angular2/angular2.dart' show Injectable;
import 'package:fnx_config/fnx_config_read.dart';

@Injectable()
class Configuration {
  Configuration() : firebaseUrl = 'https://election-au-2016.firebaseio.com/';

  /// Which firebase to connect to.
  final String firebaseUrl;

  /// Which election we are going to listen to. This is used as a sub-directory
  /// of [firebaseUrl] when constructing a Firebase reference.
  final String election = 'v0-prod';

  /// Which API server to connect to.
  /// See ./conf/configuration_debug.yaml and ./conf/configuration_release.yaml.
  final String apiBaseUrl = fnxConfig()["apiBaseUrl"];

  /// Build ID for enabling auto-update of browsers via firebase key
  final num buildId = 2016060101; // YYYYMMDDVV

  final bool languages_enabled = true;

  /// Locales supported.
  final Map<String, String> locales = {"en": "English", "es": "español"};

  /// Path to the polling place icon
  final String pollingPlaceIconUrl = '/static/ic_box.png';

  final int maxZoomLevelToIgnorePollingPlaces = 8;
  final int minZoomLevelToShowUngroupedPollingPlaces = 14;
}
