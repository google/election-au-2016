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

import 'package:google_maps/google_maps.dart';

var lightMapStyle = <MapTypeStyle>[
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ALL
    ..elementType = MapTypeStyleElementType.GEOMETRY
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..color = "#ffffff"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ALL
    ..elementType = MapTypeStyleElementType.LABELS_TEXT_FILL
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..color = "#455a64"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ALL
    ..elementType = MapTypeStyleElementType.LABELS_ICON
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..saturation = -100],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ADMINISTRATIVE_COUNTRY
    ..elementType = MapTypeStyleElementType.ALL
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..visibility = "off"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ADMINISTRATIVE_COUNTRY
    ..elementType = MapTypeStyleElementType.LABELS_TEXT
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..lightness = 50],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ADMINISTRATIVE_PROVINCE
    ..elementType = MapTypeStyleElementType.GEOMETRY_STROKE
    ..stylers = <MapTypeStyler>[
      new MapTypeStyler()
        ..color = "#ffffff"
        ..weight = 4.0
    ],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ADMINISTRATIVE_PROVINCE
    ..elementType = MapTypeStyleElementType.LABELS_TEXT
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..lightness = 40],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ADMINISTRATIVE_LOCALITY
    ..elementType = MapTypeStyleElementType.LABELS_TEXT_FILL
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..color = "#546e7a"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.POI
    ..elementType = MapTypeStyleElementType.ALL
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..visibility = "off"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.POI
    ..elementType = MapTypeStyleElementType.GEOMETRY
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..color = "#eeeeee"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.POI_PARK
    ..elementType = MapTypeStyleElementType.ALL
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..visibility = "on"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.POI_PARK
    ..elementType = MapTypeStyleElementType.GEOMETRY
    ..stylers = <MapTypeStyler>[
      new MapTypeStyler()
        ..color = "#eceff1"
        ..lightness = 30
    ],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ROAD
    ..elementType = MapTypeStyleElementType.ALL
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..lightness = 10],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ROAD
    ..elementType = MapTypeStyleElementType.GEOMETRY
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..color = "#eceff1"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ROAD
    ..elementType = MapTypeStyleElementType.LABELS_ICON
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..lightness = 25],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ROAD_HIGHWAY
    ..elementType = MapTypeStyleElementType.GEOMETRY
    ..stylers = <MapTypeStyler>[
      new MapTypeStyler()
        ..color = "#cfd8dc"
        ..lightness = 10
    ],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ROAD_HIGHWAY
    ..elementType = MapTypeStyleElementType.GEOMETRY_STROKE
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..visibility = "off"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ROAD_HIGHWAY
    ..elementType = MapTypeStyleElementType.LABELS_ICON
    ..stylers = <MapTypeStyler>[
      new MapTypeStyler()
        ..lightness = 30
        ..gamma = 1.0
    ],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.ROAD_LOCAL
    ..elementType = MapTypeStyleElementType.GEOMETRY_STROKE
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..visibility = "off"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.TRANSIT
    ..elementType = MapTypeStyleElementType.ALL
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..lightness = 0],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.TRANSIT
    ..elementType = MapTypeStyleElementType.LABELS_ICON
    ..stylers = <MapTypeStyler>[
      new MapTypeStyler()
        ..lightness = 0
        ..visibility = "off"
    ],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.TRANSIT_LINE
    ..elementType = MapTypeStyleElementType.GEOMETRY
    ..stylers = <MapTypeStyler>[
      new MapTypeStyler()
        ..color = "#eceff1"
        ..lightness = 25
    ],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.TRANSIT_STATION
    ..elementType = MapTypeStyleElementType.GEOMETRY
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..color = "#eeeeee"],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.WATER
    ..elementType = MapTypeStyleElementType.ALL
    ..stylers = <MapTypeStyler>[
      new MapTypeStyler()
        ..color = "#d9e0e3"
        ..lightness = 20
    ],
  new MapTypeStyle()
    ..featureType = MapTypeStyleFeatureType.WATER
    ..elementType = MapTypeStyleElementType.LABELS_TEXT_FILL
    ..stylers = <MapTypeStyler>[new MapTypeStyler()..color = "#b0bec5"],
];
