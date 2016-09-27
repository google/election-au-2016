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
	"bytes"
	"fmt"
	"net/http"

	"google.golang.org/appengine"
	gaelog "google.golang.org/appengine/log"
	"google.golang.org/appengine/memcache"
)

// To bulk invalidate memcache, increment this counter and re-deploy the app
const cacheKey = "2016063002" //YYYYMMDDVV

func appEngineMiddleware(h http.Handler) http.Handler {
	return http.HandlerFunc(
		func(w http.ResponseWriter, r *http.Request) {
			ctx := appengine.NewContext(r)
			url := fmt.Sprintf("%s&cache_key=%s", r.URL.String(), cacheKey)
			item, err := memcache.Get(ctx, url)
			if err != nil {
				gaelog.Debugf(ctx, "Failed to get from memcache for %v: %v", url, err)
			}
			if item != nil {
				w.Header().Set("Cache-control", "public, max-age=120")
				w.Header().Set("Content-type", "application/json")
				w.Write(item.Value)
				return
			}
			// TODO: this is overkill, and we don't actually copy the headers back
			// properly but prob. good enough for our requirements.
			rw := NewRecorder()
			h.ServeHTTP(rw, r)
			if !rw.wroteHeader || rw.Body == nil {
				// We expect the given handler h to always come back with a response.
				gaelog.Debugf(ctx, "Handler didn't write to ResponseWriter: %v", url)
				http.Error(w, "Internal server error", http.StatusInternalServerError)
				return
			}
			if rw.Code != http.StatusOK {
				errorMessage := rw.Body.String()
				gaelog.Debugf(ctx, "Handler returned non-200 response for %v: %v", url, errorMessage)
				http.Error(w, errorMessage, rw.Code)
				return
			}
			err = memcache.Set(ctx, &memcache.Item{Key: url, Value: rw.Body.Bytes()})
			if err != nil {
				gaelog.Errorf(ctx, "Failed to set memcache for %v: %v", url, err)
			}
			w.Header().Set("Cache-control", "public, max-age=120")
			w.Header().Set("Content-type", "application/json")
			w.Write(rw.Body.Bytes())
		})
}

// Copied from httptest:

// ResponseRecorder is an implementation of http.ResponseWriter that
// records its mutations for later inspection in tests.
type ResponseRecorder struct {
	Code      int           // the HTTP response code from WriteHeader
	HeaderMap http.Header   // the HTTP response headers
	Body      *bytes.Buffer // if non-nil, the bytes.Buffer to append written data to
	Flushed   bool

	result      *http.Response // cache of Result's return value
	snapHeader  http.Header    // snapshot of HeaderMap at first Write
	wroteHeader bool
}

// NewRecorder returns an initialized ResponseRecorder.
func NewRecorder() *ResponseRecorder {
	return &ResponseRecorder{
		HeaderMap: make(http.Header),
		Body:      new(bytes.Buffer),
		Code:      200,
	}
}

// Header returns the response headers.
func (rw *ResponseRecorder) Header() http.Header {
	m := rw.HeaderMap
	if m == nil {
		m = make(http.Header)
		rw.HeaderMap = m
	}
	return m
}

// writeHeader writes a header if it was not written yet and
// detects Content-Type if needed.
//
// bytes or str are the beginning of the response body.
// We pass both to avoid unnecessarily generate garbage
// in rw.WriteString which was created for performance reasons.
// Non-nil bytes win.
func (rw *ResponseRecorder) writeHeader(b []byte, str string) {
	if rw.wroteHeader {
		return
	}
	if len(str) > 512 {
		str = str[:512]
	}

	m := rw.Header()

	_, hasType := m["Content-Type"]
	hasTE := m.Get("Transfer-Encoding") != ""
	if !hasType && !hasTE {
		if b == nil {
			b = []byte(str)
		}
		m.Set("Content-Type", http.DetectContentType(b))
	}

	rw.WriteHeader(200)
}

// Write always succeeds and writes to rw.Body, if not nil.
func (rw *ResponseRecorder) Write(buf []byte) (int, error) {
	rw.writeHeader(buf, "")
	if rw.Body != nil {
		rw.Body.Write(buf)
	}
	return len(buf), nil
}

// WriteString always succeeds and writes to rw.Body, if not nil.
func (rw *ResponseRecorder) WriteString(str string) (int, error) {
	rw.writeHeader(nil, str)
	if rw.Body != nil {
		rw.Body.WriteString(str)
	}
	return len(str), nil
}

// WriteHeader sets rw.Code. After it is called, changing rw.Header
// will not affect rw.HeaderMap.
func (rw *ResponseRecorder) WriteHeader(code int) {
	if rw.wroteHeader {
		return
	}
	rw.Code = code
	rw.wroteHeader = true
	if rw.HeaderMap == nil {
		rw.HeaderMap = make(http.Header)
	}
	rw.snapHeader = cloneHeader(rw.HeaderMap)
}

func cloneHeader(h http.Header) http.Header {
	h2 := make(http.Header, len(h))
	for k, vv := range h {
		vv2 := make([]string, len(vv))
		copy(vv2, vv)
		h2[k] = vv2
	}
	return h2
}

// Flush sets rw.Flushed to true.
func (rw *ResponseRecorder) Flush() {
	if !rw.wroteHeader {
		rw.WriteHeader(200)
	}
	rw.Flushed = true
}
