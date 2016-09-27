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
	"html/template"
	"net/http"
)

const (
	// DO NOT SUBMIT - replace with dummy key / empty key.
	MAPS_API_KEY string = "INSERT_API_KEY"
)

var (
	indexTemplate = template.Must(template.ParseFiles("dist/index.html"))
)

func processLocale(locale string) string {
	if locale == "" {
		return "en"
	}
	return locale
}

// Index is the http.HandlerFunc that serve the index.html page of our application.
// It's exported because it is handled differently to the other API handlers.
func Index(w http.ResponseWriter, r *http.Request) {
	// TODO: A bit ugly, needed because of addCommonHeaders applied globally.
	w.Header().Del("Content-Disposition")
	data := struct {
		MAPS_API_KEY string
		Language     string
	}{
		MAPS_API_KEY,
		processLocale(r.FormValue("hl")),
	}
	if err := indexTemplate.Execute(w, data); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}
