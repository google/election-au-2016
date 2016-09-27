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
	"testing"

	shp "github.com/jonas-p/go-shp"
)

type xy struct {
	x, y float64
}

type closedPoly struct {
	name string
	vert []xy
}

type testResult struct {
	name   string
	inside []bool
}

var expected []testResult = []testResult{
	{"square", []bool{true, true}},
	{"square hole", []bool{true, true}},
	// {"strange", []bool{false, false}},
	{"exagon", []bool{false, false}},
}

var tcp = []closedPoly{
	{"square", []xy{{0, 0}, {10, 0}, {10, 10}, {0, 10}}},
	{"square hole", []xy{{0, 0}, {10, 0}, {10, 10}, {0, 10}, {0, 0},
		{2.5, 2.5}, {7.5, 2.5}, {7.5, 7.5}, {2.5, 7.5}, {2.5, 2.5}}},
	// {"strange", []xy{{0, 0}, {2.5, 2.5}, {0, 10}, {2.5, 7.5}, {7.5, 7.5},
	// 	{10, 10}, {10, 0}, {2.5, 2.5}}},
	{"exagon", []xy{{3, 0}, {7, 0}, {10, 5}, {7, 10}, {3, 10}, {0, 5}}},
}

var txy = []xy{{1, 2}, {2, 1}}

func (cp *closedPoly) toShpPolygon() shp.Polygon {
	if len(cp.vert) == 0 {
		return shp.Polygon(*shp.NewPolyLine([][]shp.Point{}))
	}
	points := make([]shp.Point, len(cp.vert)+1)
	for i, xy := range cp.vert {
		points[i] = shp.Point{xy.x, xy.y}
	}
	// closedPoly doesn't require last point to equal the first - shp.Polygon does.
	points[len(points)-1] = points[0]
	return shp.Polygon(*shp.NewPolyLine([][]shp.Point{points}))
}

func TestPointInPolygon(t *testing.T) {
	for i, cp := range tcp {
		t.Logf("%s:", cp.name)
		pg := cp.toShpPolygon()
		for j, xy := range txy {
			isInside := inside(shp.Point{xy.x, xy.y}, pg)
			t.Log(xy, isInside)
			if isInside != expected[i].inside[j] {
				t.Fail()
			}
		}
	}
}

// Expected log..
// square:
// {1 2} true
// {2 1} true
// square hole:
// {1 2} true
// {2 1} true
// strange:
// {1 2} false
// {2 1} false
// exagon:
// {1 2} false
// {2 1} false

func NewPolygon(_ string, points [][]shp.Point) shp.Polygon {
	polygon := shp.Polygon(*shp.NewPolyLine(points))
	// For some reason Parts isn't fully initialized by calling NewPolyline.
	runningIndex := int32(0)
	for i, part := range points {
		// debug:
		// fmt.Printf("Part %v is set to %v\n", i, runningIndex)
		polygon.Parts[i] = runningIndex
		// yes, the last len() is omitted..
		runningIndex += int32(len(part))
	}
	return polygon
}

var polygonsWithHoles = []shp.Polygon{
	NewPolygon("square with hole", [][]shp.Point{
		{{0, 0}, {10, 0}, {10, 10}, {0, 10}, {0, 0}},
		{{2.5, 2.5}, {7.5, 2.5}, {7.5, 7.5}, {2.5, 7.5}, {2.5, 2.5}}}),
	NewPolygon("exagon with two square holes", [][]shp.Point{
		{{3, 0}, {7, 0}, {10, 5}, {7, 10}, {3, 10}, {0, 5}, {3, 0}},
		{{2.5, 2.5}, {7.5, 2.5}, {7.5, 7.5}, {2.5, 7.5}, {2.5, 2.5}},
		{{4, 1}, {6, 1}, {6, 2}, {4, 2}, {4, 1}}}),
}

var pointsToTest = []xy{{1, 2}, {2, 1}, {4, 4}, {8, 8}}
var expected2 = []testResult{
	{"square with hole", []bool{true, true, false, true}},
	{"exagon with two square holes", []bool{false, false, false, true}},
}

func TestPointInPolygonWithHole(t *testing.T) {
	for i, polygon := range polygonsWithHoles {
		result := expected2[i]
		t.Logf("%s:", result.name)
		for j, xy := range pointsToTest {
			isInside := inside(shp.Point{xy.x, xy.y}, polygon)
			t.Log(xy, isInside)
			if result.inside[j] != isInside {
				t.Fail()
			}
		}
	}
}
