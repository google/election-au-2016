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
	"net/http"
	"strconv"
	"strings"

	"github.com/gorilla/mux"
)

const allowEncodedPolylineFeatureCollection = true

// NewAPIHandler creates a single http.Handler for the election library HTTP API.
// Note that index is a separate http.HandlerFunc, as it requires a different set of headers.
func NewAPIHandler() http.Handler {
	initSpatial()
	r := mux.NewRouter()
	r.HandleFunc("/electorates/{zoom}", electoratesQuery)
	r.HandleFunc("/location", locationQuery)
	r.HandleFunc("/viewport/{zoom}", viewportQuery)
	r.HandleFunc("/zoom_buckets", zoomBucketsQuery)
	r.HandleFunc("/polling_places", pollingPlacesQuery)
	return r
}

func addCommonHeaders(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	// NOTE: to debug the API directly in the browser, remove this header:
	w.Header().Set("Content-Disposition", "attachment")
}

// CommonHeadersMiddleware adds common headers to the response and delegates to h
// for further processing of the request.
func CommonHeadersMiddleware(h http.Handler) http.Handler {
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			addCommonHeaders(w, r)
			h.ServeHTTP(w, r)
		})
}

func viewportQuery(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	zoom, originalZoom, err := parseZoomParameter(vars["zoom"])
	if err != nil {
		http.Error(w, "Invalid zoom", http.StatusBadRequest)
		return
	}
	rect, err := ParseBboxToRect(r.FormValue("bbox"))
	if err != nil {
		http.Error(w, "Invalid bbox", http.StatusBadRequest)
		return
	}
	vr := queryViewport(rect, zoom, originalZoom)
	w.Header().Set("Cache-control", "public, max-age=120")
	w.Header().Set("Content-type", "application/json")
	err = json.NewEncoder(w).Encode(vr)
	if err != nil {
		http.Error(w, "Invalid JSON response", http.StatusInternalServerError)
	}
}

func electoratesQuery(w http.ResponseWriter, r *http.Request) {
	if len(electorates) == 0 {
		http.Error(w, "No electorates loaded", http.StatusInternalServerError)
		return
	}
	vars := mux.Vars(r)
	zoom, _, err := parseZoomParameter(vars["zoom"])
	if err != nil {
		http.Error(w, "Invalid zoom", http.StatusBadRequest)
		return
	}
	ids := r.FormValue("ids")
	if ids == "" {
		http.Error(w, "No electorate ID specified", http.StatusBadRequest)
		return
	}
	fc, err := queryElectorates(zoom, ids)
	if err != nil {
		http.Error(w, "Invalid electorates", http.StatusBadRequest)
		return
	}
	var epfc MarshalJSON = fc
	if allowEncodedPolylineFeatureCollection {
		epfc = maybeConvertToEncodedPolylineFeatureCollection(fc)
	}
	w.Header().Set("Cache-control", "public, max-age=120")
	w.Header().Set("Content-type", "application/json")
	err = json.NewEncoder(w).Encode(epfc)
	if err != nil {
		http.Error(w, "Invalid JSON response", http.StatusInternalServerError)
	}
}

func zoomBucketsQuery(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Cache-control", "public, max-age=120")
	w.Header().Set("Content-type", "application/json")
	err := json.NewEncoder(w).Encode(zoomBuckets)
	if err != nil {
		http.Error(w, "Invalid JSON response", http.StatusInternalServerError)
	}
}

func locationQuery(w http.ResponseWriter, r *http.Request) {
	location := r.FormValue("location")
	if location == "" {
		http.Error(w, "location parameter required", http.StatusBadRequest)
		return
	}
	components := strings.Split(location, ",")
	if len(components) != 2 {
		http.Error(w, "location parameter invalid format", http.StatusBadRequest)
		return
	}
	lat, err := strconv.ParseFloat(components[0], 64)
	if err != nil {
		http.Error(w, "invalid lat", http.StatusBadRequest)
		return
	}
	lng, err := strconv.ParseFloat(components[1], 64)
	if err != nil {
		http.Error(w, "invalid lng", http.StatusBadRequest)
		return
	}
	name := queryLocation(lng, lat)
	if name == "" {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Cache-control", "public, max-age=120")
	w.Header().Set("Content-type", "application/json")
	response := struct{ Name string }{Name: name}
	err = json.NewEncoder(w).Encode(response)
	if err != nil {
		http.Error(w, "Invalid JSON response", http.StatusInternalServerError)
	}
}

func pollingPlacesQuery(w http.ResponseWriter, r *http.Request) {
	ids := r.FormValue("ids")
	if ids == "" {
		http.Error(w, "No electorate ID specified", http.StatusBadRequest)
		return
	}
	fc, err := queryPollingPlaces(ids)
	if err != nil {
		http.Error(w, "Invalid polling places", http.StatusBadRequest)
		return
	}
	w.Header().Set("Cache-control", "public, max-age=120")
	w.Header().Set("Content-type", "application/json")
	err = json.NewEncoder(w).Encode(fc)
	if err != nil {
		http.Error(w, "Invalid JSON response", http.StatusInternalServerError)
	}
}
