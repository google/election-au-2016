#!/bin/bash

# Copyright 2016 Google Inc. All rights reserved.
#
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
# file except in compliance with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific language governing
# permissions and limitations under the License.

LAYERNAME="COM_ELB"

pushd /geodata
for f in *.zip; do
  echo "Unzipping $f to $f.d"
  unzip "$f" -d "$f.d"
  mkdir -p "$f.d.out"
  echo "Reprojecting $f.d to WGS84, saving in ESRI Shapefile format in $f.d.out"
  (set -x; \
    ogr2ogr -t_srs EPSG:4326 -nlt PROMOTE_TO_MULTI -f "ESRI Shapefile" \
    -sql \
    `# Note Elect_div as sortname: Elect_div is camel-cased, sortname is partial upper-cased.` \
"SELECT Elect_div as sortname, State as state, Area_SqKm as area_sqkm, Numccds as numccds "\
"FROM $LAYERNAME" \
    "$f.d.out" "$f.d" \
    && rm -rf "$f.d")

  # Should be one .shp file.
  shp=`find $f.d.out -name *.shp`
  echo "Splitting multipolygons, adding gis_id (to enumerate polygons), per-polygon area and centroids."
  (set -x; \
    mapshaper -i $shp \
      -explode \
      -each 'gis_id=$.id, cent_long=$.innerX, cent_lat=$.innerY, area=($.area / 1000000.0)' \
      -o $shp force)

  echo "Simplifying shapefiles in $f.d.out, output will use structure national_elb/[zoom_level]/ ."
  simpl_zoom=("6" "8" "12" "16")
  # TODO mapshaper can treat shared polygon borders differently to external borders - investigate.
  simpl_params=(
    "-simplify 0.001 interval=100 -filter-islands min-area=20000000 remove-empty" \
    "-simplify 0.01 interval=10 -filter-islands min-area=1000000 remove-empty" \
    "-simplify 0.2 -filter remove-empty" \
    "-simplify 0.7 -filter remove-empty")
  count=0
  for params in "${simpl_params[@]}"; do
    # Take filename without extension.
    output="national_elb/${simpl_zoom[$count]}/$LAYERNAME.shp"
    mkdir -p `dirname $output`
    (set -x; mapshaper -i $shp $params -o $output)
    (( count++ ))
  done
done
popd
