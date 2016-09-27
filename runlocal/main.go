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

package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gorilla/handlers"

	election "../go_backend"
)

// BaseDistFolder represents the subfolder (relative to the running application) where data files
// and assets can be found to be served by this application.
const BaseDistFolder = "Dist"

func main() {
	// LoggingHandler - Helpful for local development / debugging.
	index := handlers.LoggingHandler(
		os.Stdout,
		http.HandlerFunc(election.Index))
	api := handlers.LoggingHandler(
		os.Stdout,
		election.CommonHeadersMiddleware(
			election.NewAPIHandler()))
	rootSlash := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// The "/" pattern matches everything, so we need to check
		// that we're at the root here.
		if r.URL.Path == "/" {
			index.ServeHTTP(w, r)
			return
		}
		api.ServeHTTP(w, r)
	})
	http.Handle("/", rootSlash)
	http.Handle("/embed", index)
	http.Handle("/static/", http.FileServer(http.Dir(BaseDistFolder)))
	//http.StripPrefix("/static/", http.FileServer(http.Dir("static"))))
	log.Fatal(http.ListenAndServe(":8090", nil))
}
