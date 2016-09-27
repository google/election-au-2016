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

package appengine_election

import (
	"net/http"
	"strings"

	"golang.org/x/net/context"
	"google.golang.org/appengine"
)

func init() {
	index := httpsMiddleware(http.HandlerFunc(electionIndex))
	api := httpsMiddleware(
		electionCommonHeadersMiddleware(
			appEngineMiddleware(
				electionNewAPIHandler())))
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
}

func isProd(ctx context.Context) bool {
	v := appengine.VersionID(ctx)
	return (strings.HasPrefix(v, "prod.") || strings.HasPrefix(v, "qa.")) &&
		!appengine.IsDevAppServer()
}

func httpsMiddleware(h http.Handler) http.Handler {
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			ctx := appengine.NewContext(r)

			httpsOnly := isProd(ctx)
			if httpsOnly && r.URL.Scheme != "https" {
				url := *r.URL
				url.Scheme = "https"
				http.Redirect(w, r, url.String(), http.StatusFound)
				return
			}
			h.ServeHTTP(w, r)
		})
}
