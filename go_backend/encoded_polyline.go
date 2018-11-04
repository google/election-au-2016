/*
 * Copyright 2016 Google Inc. All rights reserved.
 *
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations
 * under the License.
 */

package election

import (
	"encoding/json"

	"github.com/paulmach/go.geojson"
	"github.com/twpayne/go-polyline"
)

// EncodedGeometry correlates to a GeoJSON linear ring geometry, replacing
// coordinates with the encoded representation.
type EncodedGeometry struct {
	Type        string     `json:"type"`
	Coordinates [][]string `json:"coordinates"`
}

// EncodedPolylineFeature correlates to a GeoJSON feature, allowing
// EncodedGeometry to replace Geometry.
type EncodedPolylineFeature struct {
	ID          string    `json:"id,omitempty"`
	Type        string    `json:"type"`
	BoundingBox []float64 `json:"bbox,omitempty"`
	// Geometry overrides the Feature's Geometry, allowing us to use the
	// encoded polyline algorithm.
	Geometry   *EncodedGeometry       `json:"geometry"`
	Properties map[string]interface{} `json:"properties"`
}

// MarshalJSON returns JSON in a byte slice from a given encoded polyline
// feature.
func (epf *EncodedPolylineFeature) MarshalJSON() ([]byte, error) {
	// Must use *epf to avoid infinite loop.
	return json.Marshal(*epf)
}

// EncodedPolylineFeatureCollection correlates to a GeoJSON feature collection,
// but allows flexibility in the features it contains.
type EncodedPolylineFeatureCollection struct {
	Type        string        `json:"type"`
	BoundingBox []float64     `json:"bbox,omitempty"`
	Features    []MarshalJSON `json:"features"`
}

// MarshalJSON returns JSON in a byte slice from a given encoded polyline
// feature collection.
func (epfc *EncodedPolylineFeatureCollection) MarshalJSON() ([]byte, error) {
	// Must use *epfc to avoid infinite loop.
	return json.Marshal(*epfc)
}

// MarshalJSON provides a common interface between geojson.Feature,
// geojson.FeatureCollection and our encoded polyline implementation.
type MarshalJSON interface {
	MarshalJSON() ([]byte, error)
}

func convertToEncodedPolylineFeature(f *geojson.Feature) (*EncodedPolylineFeature, bool) {
	if f.Geometry.Type != "MultiPolygon" {
		return nil, false
	}
	// 3 levels of nesting: Multi then polygon then linear ring; linear
	// ring is string-encoded.
	var encodedMultiPolygon [][]string
	for _, polygon := range f.Geometry.MultiPolygon {
		var encodedPolygon []string
		for _, linearRing := range polygon {
			// http://geojson.org/geojson-spec.html#positions: long,lat.
			// https://developers.google.com/maps/documentation/utilities/polylineutility: lat,long.
			invertedCoords := make([][]float64, len(linearRing))
			for i, coords := range linearRing {
				invertedCoords[i] = []float64{coords[1], coords[0]}
			}
			encoded := string(polyline.EncodeCoords(invertedCoords))
			encodedPolygon = append(encodedPolygon, encoded)
		}
		encodedMultiPolygon = append(encodedMultiPolygon, encodedPolygon)
	}
	encodedGeom := &EncodedGeometry{
		Type:        "EncodedMultiPolygon",
		Coordinates: encodedMultiPolygon,
	}
	return &EncodedPolylineFeature{
		ID:          f.ID.(string),
		Type:        f.Type,
		BoundingBox: f.BoundingBox,
		Geometry:    encodedGeom,
		Properties:  f.Properties,
	}, true
}

func maybeConvertToEncodedPolylineFeatureCollection(fc *geojson.FeatureCollection) MarshalJSON {
	var features []MarshalJSON
	for _, f := range fc.Features {
		epf, ok := convertToEncodedPolylineFeature(f)
		if !ok {
			features = append(features, f)
			continue
		}
		features = append(features, epf)
	}
	return &EncodedPolylineFeatureCollection{
		Type:        fc.Type,
		BoundingBox: fc.BoundingBox,
		Features:    features,
	}
}
