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

import "github.com/jonas-p/go-shp"

// Adapted from: http://rosettacode.org/wiki/Ray-casting_algorithm#Go The
// article considers 'closedPoly' to contain a series of coordinates, but
// unlike shp.Polygon it doesn't expect the last coordinate to be identical to
// the first one.  Also, the article only considers a single linear ring; In
// theory shp.Polygon may contain multiple polygons, but in this project we've
// separated multi polygons so that shp.Polygon only ever represents a single
// polygon, albeit potentially with holes (therefore, multiple linear rings).

func inside(pt shp.Point, pg shp.Polygon) bool {
	in := false
	// Add the length of the points slice as the last element in "parts" to
	// avoid another step after the for loop.
	parts := append(pg.Parts, int32(len(pg.Points)))
	prev := int32(0)
	for _, next := range parts[1:] {
		linearRing := pg.Points[prev:next]
		prev = next
		lastIndex := len(linearRing) - 1
		if len(linearRing) < 3 || linearRing[0] != linearRing[lastIndex] {
			return false
		}
		inLinearRing := rayIntersectsSegment(pt, linearRing[lastIndex-1], linearRing[0])
		for i := 1; i < lastIndex-1; i++ {
			if rayIntersectsSegment(pt, linearRing[i-1], linearRing[i]) {
				inLinearRing = !inLinearRing
			}
		}
		// We're assuming that inner linear rings never overlap, so: In
		// polygons without holes this could be called zero or one
		// times.  In polygons with holes this could be called up to
		// two times.
		if inLinearRing {
			in = !in
		}
	}
	return in
}

func rayIntersectsSegment(p, a, b shp.Point) bool {
	return (a.Y > p.Y) != (b.Y > p.Y) &&
		p.X < (b.X-a.X)*(p.Y-a.Y)/(b.Y-a.Y)+a.X
}
