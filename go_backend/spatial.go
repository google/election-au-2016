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
	"fmt"
	"log"
	"math"
	"sort"
	"strconv"
	"strings"

	rtree "github.com/dhconnelly/rtreego"
	"github.com/fatih/structs"
	shp "github.com/jonas-p/go-shp"
	"github.com/paulmach/go.geojson"
)

func BboxToRect(bbox *shp.Box) (*rtree.Rect, error) {
	height := bbox.MaxY - bbox.MinY
	width := bbox.MaxX - bbox.MinX
	// It's possible that our bounding box's rightmost edge is in a
	// negative coordinate space because we've wrapped over the date line.
	// If this is the case, we need to add 360 so that the rtree Rect
	// creation works.
	if width < 0 {
		width += 360
	}
	return rtree.NewRect(
		rtree.Point{bbox.MinX, bbox.MinY},
		[]float64{width, height})
}

func (e *Electorate) AssignToFeature(feature *geojson.Feature) {
	feature.ID = string(e.id)
	feature.Properties["name"] = e.name
	feature.Properties["state"] = e.state
	feature.Properties["area_sqkm"] = e.areaSqkm
}

func ParseBboxToRect(s string) (*rtree.Rect, error) {
	split := strings.Split(s, ",")
	if len(split) != 4 {
		return nil, fmt.Errorf("Expected a comma separated list, e.g. 'MinX,MinY,MaxX,MaxY'. Received: %v", s)
	}
	values := [4]float64{}
	for i := range values {
		value, err := strconv.ParseFloat(split[i], 64)
		if err != nil {
			return nil, err
		}
		values[i] = value
	}
	// Caller sends in lat,long but shp.Box requires the reverse order.
	return BboxToRect(&shp.Box{MinX: values[1], MinY: values[0], MaxX: values[3], MaxY: values[2]})
}

func ShpPolygonToGeojsonFeature(eps []*ElectoratePolygon) *geojson.Feature {
	var polygons [][][][]float64
	var pointInPolygon [][2]float32
	for _, ep := range eps {
		points := make([][]float64, ep.NumPoints)
		for i, value := range ep.Points {
			// geojson dictates long,lat order
			points[i] = []float64{value.X, value.Y}
		}
		var polygon [][][]float64
		var linearRing [][]float64
		prevIndex := 0
		// Add to the parts slice a fake index, to avoid having to take
		// another step after the for loop.
		parts := append(ep.Parts, ep.NumPoints)
		for i := 1; i <= int(ep.NumParts); i++ {
			partIndex := int(parts[i])
			linearRing = points[prevIndex:partIndex]
			prevIndex = partIndex
			polygon = append(polygon, linearRing)
		}
		polygons = append(polygons, polygon)
		pointInPolygon = append(pointInPolygon, [2]float32{
			ep.centLong,
			ep.centLat,
		})
	}
	feature := geojson.NewMultiPolygonFeature(polygons...)
	feature.Properties["centroid"] = pointInPolygon
	return feature
}

func electorateToGeoJsonFeature(id ElectorateID, z ZoomLevel) (*geojson.Feature, error) {
	electorate, ok := electorates[ElectorateID(id)]
	if !ok {
		return nil, fmt.Errorf("Electorate %v does not exist", id)
	}
	poly := electorate.polygons[z]
	feature := ShpPolygonToGeojsonFeature(poly)
	bbox := electorate.bbox
	feature.BoundingBox = []float64{bbox.MinX, bbox.MinY, bbox.MaxX, bbox.MaxY}
	electorate.AssignToFeature(feature)
	return feature, nil
}

// EarthRadius is a rough estimate of earth's radius in km at latitude 0 if earth was a perfect sphere.
const EarthRadius = 6378.137

// EarthRadiusSq is a rough estimate of earth's radius, squared.
const EarthRadiusSq = EarthRadius * EarthRadius

// sin returns the sine function (like math.sin) but accepts degrees as input.
func sin(degree float64) float64 {
	return math.Sin(degree * math.Pi / 180)
}

// cos returns the cosine function (like math.cos) but accepts degrees as input.
func cos(degree float64) float64 {
	return math.Cos(degree * math.Pi / 180)
}

// calcMinSquareAreaEstimate returns a rough estimate of the area of a bounding box given by rect.
func calcMinSquareAreaEstimate(rect *rtree.Rect) float64 {
	long1 := rect.PointCoord(0)
	lat1 := rect.PointCoord(1)
	long2 := long1 + rect.LengthsCoord(0)
	lat2 := lat1 + rect.LengthsCoord(1)
	// debug:
	// log.Printf("Coord: {%v, %v}, {%v, %v}.", lat1, long1, lat2, long2)
	if long2-long1 > (lat2-lat1)*2 {
		long2 = long1 + (lat2-lat1)*2
	} else {
		lat2 = lat1 + (long2-long1)/2
	}
	return EarthRadiusSq * math.Pi * (sin(lat2) - sin(lat1)) * (long2 - long1) / 180
}

// NoZoomLevel is the devault zoom level.
const NoZoomLevel ZoomLevel = ZoomLevel(0)

func chooseBestZoomBucket(z int) ZoomLevel {
	for _, zoomLevel := range zoomBuckets {
		if z <= int(zoomLevel) {
			return zoomLevel
		}
	}
	return highestZoomLevel
}

func parseZoomParameter(z string) (ZoomLevel, int, error) {
	if z == "" {
		return NoZoomLevel, 0, fmt.Errorf("No zoom specified")
	}
	zoom, err := strconv.Atoi(z)
	if err != nil {
		return NoZoomLevel, 0, fmt.Errorf("Expected int for zoom")
	}
	return chooseBestZoomBucket(zoom), zoom, nil
}

type viewportResponse struct {
	*geojson.FeatureCollection
	rect         *rtree.Rect
	originalZoom int
	zoom         ZoomLevel
	electorates  []rtree.Spatial
}

func NewViewportResponse(rect *rtree.Rect, zoom ZoomLevel, originalZoom int) *viewportResponse {
	return &viewportResponse{
		FeatureCollection: geojson.NewFeatureCollection(),
		rect:              rect,
		zoom:              zoom,
		originalZoom:      originalZoom,
	}
}

const PolygonAreaToViewportThresholdRatio = 32
const MinNumOfElectoratesToReturnAll = 100

const TypeElectorateIds = "electorate_ids"
const TypeElectorateLabel = "electorate_label"
const TypePollingPlace = "polling_place"
const TypePollingPlaceGroup = "polling_place_group"

func (vr *viewportResponse) populateElectorateIdsAndAreas() {
	bboxArea := calcMinSquareAreaEstimate(vr.rect)
	var ids []string
	titleLocations := map[ElectorateID][][]float64{}
	featuresFound := electorateTree.SearchIntersect(vr.rect)
	for i, spatial := range featuresFound {
		electorate, ok := spatial.(*Electorate)
		if !ok {
			log.Printf("Couldn't convert spatial %v to electorate, viewport bbox: %v, zoom: %v", i, vr.BoundingBox, vr.zoom)
			continue
		}
		ids = append(ids, string(electorate.id))
		// Workout for the given electorate, which of its polygons are large enough that we should show the electorate name on them.
		for _, polygon := range electorate.polygons[zoomBuckets[0]] {
			// roughly, if a polygon is larger than a given ratio of a minimal square that fits in the bbox, show its name.
			// debug:
			// log.Printf("polygon area: %v. bbox area: %v.", float64(polygon.area), bboxArea)
			if float64(polygon.area)*PolygonAreaToViewportThresholdRatio >= bboxArea {
				titleLocations[electorate.id] =
					append(titleLocations[electorate.id], []float64{
						float64(polygon.centLong),
						float64(polygon.centLat),
					})
			}
		}
	}
	// Over a certain thershold, no point in returning separate ID for each electorate,
	// just use 'all'.
	if len(ids) > MinNumOfElectoratesToReturnAll {
		ids = []string{"all"}
	} else {
		sort.Strings(ids)
	}
	// We return only a set of IDs for electorates, so include no geometry (nil)
	electorateIdsFeature := geojson.NewFeature(nil)
	electorateIdsFeature.ID = TypeElectorateIds
	electorateIdsFeature.Properties["type"] = TypeElectorateIds
	electorateIdsFeature.Properties["electorates"] = ids
	vr.AddFeature(electorateIdsFeature)

	// For each electorate that had polygons large enough to show a title over them,
	// add a single multipoint feature with the id and name of the electorate.
	for id, locations := range titleLocations {
		titleLocationsFeature := geojson.NewMultiPointFeature(locations...)
		titleLocationsFeature.ID = string(id)
		titleLocationsFeature.Properties["type"] = TypeElectorateLabel
		titleLocationsFeature.Properties["name"] = electorates[id].name
		vr.AddFeature(titleLocationsFeature)
	}
}

const MaxZoomLevelToIgnorePollingPlaces = 8
const MinZoomLevelToShowUngroupedPollingPlaces = 14

func (p *PollingPlace) toFeature() *geojson.Feature {
	placeFeature := geojson.NewPointFeature([]float64{
		float64(p.Lng),
		float64(p.Lat),
	})
	placeFeature.ID = strconv.Itoa(p.PollingPlaceId)
	placeFeature.Properties["type"] = TypePollingPlace
	// NOTE: Needs to be overriden to provide any sensible value. Client should consider minZoom > 0 as a useful value.
	placeFeature.Properties["minZoom"] = 0
	// TODO this is way more than is needed client-side.. we should trim this. Possibly also the polling places go-data.
	structs.FillMap(p, placeFeature.Properties)
	return placeFeature
}

func (placeGroup *pollingPlaceGroup) ID() string {
	return fmt.Sprintf("%v_%s", placeGroup.minZoom, placeGroup.IDNoZoom())
}

func (placeGroup *pollingPlaceGroup) IDNoZoom() string {
	var ids []int
	for _, pIndex := range placeGroup.pollingPlaceIndices {
		ids = append(ids, pollingPlaces[pIndex].PollingPlaceId)
	}
	sort.Ints(ids)
	strIds := make([]string, len(ids))
	for i, id := range ids {
		strIds[i] = fmt.Sprint(id)
	}
	return strings.Join(strIds, ",")
}

func (placeGroup *pollingPlaceGroup) toFeature() *geojson.Feature {
	return placeGroup.toFeatureWithID(placeGroup.ID())
}

func (placeGroup pollingPlaceGroup) toFeatureWithID(id string) *geojson.Feature {
	placeGroupFeature := geojson.NewPointFeature([]float64{
		float64(placeGroup.Lng),
		float64(placeGroup.Lat),
	})
	placeGroupFeature.ID = id
	placeGroupFeature.Properties["type"] = TypePollingPlaceGroup
	placeGroupFeature.Properties["count"] = len(placeGroup.pollingPlaceIndices)
	placeGroupFeature.Properties["minZoom"] = placeGroup.minZoom
	// Using same casing as individual polling place notation.
	placeGroupFeature.Properties["DivisionName"] = placeGroup.divisionName
	return placeGroupFeature
}

func (vr *viewportResponse) populatePollingPlaces() {
	if vr.originalZoom <= MaxZoomLevelToIgnorePollingPlaces {
		return
	}
	key := vr.originalZoom
	if key > MinZoomLevelToShowUngroupedPollingPlaces {
		key = MinZoomLevelToShowUngroupedPollingPlaces
	}
	featuresFound := polplaceTrees[key].SearchIntersect(vr.rect)
	// debug:
	// log.Printf("Found %v polling places", len(featuresFound))
	for i, spatial := range featuresFound {
		var place PollingPlace
		pps, ok := spatial.(pollingPlaceSpatial)
		if !ok {
			placeGroup, ok := spatial.(pollingPlaceGroup)
			if !ok {
				log.Printf("Couldn't convert spatial %v to PollingPlace or PollingPlaceGroup, "+
					"viewport bbox: %v, zoom: %v", i, vr.BoundingBox, vr.zoom)
				continue
			}
			if vr.originalZoom >= MinZoomLevelToShowUngroupedPollingPlaces {
				place = pollingPlaces[placeGroup.pollingPlaceIndices[0]]
				vr.AddFeature(place.toFeature())
			} else {
				vr.AddFeature(placeGroup.toFeature())
			}
			continue
		}
		place = pps.PollingPlace
		vr.AddFeature(place.toFeature())
	}
}

func queryViewport(rect *rtree.Rect, zoom ZoomLevel, originalZoom int) *viewportResponse {
	vr := NewViewportResponse(rect, zoom, originalZoom)
	vr.populateElectorateIdsAndAreas()
	return vr
}

// MaxZoomForAllElectorates is an arbitrary zoom level after which the 'all electorates' dataset becomes
// too large to send in one response.
const MaxZoomForAllElectorates = 8

func queryElectorates(zoom ZoomLevel, ids string) (*geojson.FeatureCollection, error) {
	var electorateIds []string
	if strings.ToLower(ids) == "all" {
		if int(zoom) > MaxZoomForAllElectorates {
			return nil, fmt.Errorf("ids=all isn't allowed at zoom level %v", zoom)
		}
		for id := range electorates {
			electorateIds = append(electorateIds, string(id))
		}
	} else {
		for _, id := range strings.Split(ids, ",") {
			electorateIds = append(electorateIds, id)
		}
	}
	// Since this should be a relatively large response payload, ensure the order is identical,
	// making life easier for any caching level between this app and the consumer.
	sort.Strings(electorateIds)
	fc := geojson.NewFeatureCollection()
	var fcBbox *shp.Box
	for _, id := range electorateIds {
		f, err := electorateToGeoJsonFeature(ElectorateID(id), zoom)
		if err != nil {
			return nil, fmt.Errorf("Failed retreiving electorate %v details: %v", id, err)
		}
		fc.AddFeature(f)
		fb := f.BoundingBox
		fBBox := shp.Box{MinX: fb[0], MinY: fb[1], MaxX: fb[2], MaxY: fb[3]}
		if fcBbox == nil {
			fcBbox = &fBBox
		} else {
			fcBbox.Extend(fBBox)
		}
	}
	fc.BoundingBox = []float64{fcBbox.MinX, fcBbox.MinY, fcBbox.MaxX, fcBbox.MaxY}
	return fc, nil
}

// TODO write tests for interesting cases (these seem trivial but gave the wrong results..):
// Springwood (lat, lng) -> Electorate of Macquarie
// Blacktown -> Greenway
// Prospect -> Greenway
// 48 Pirrama road Pyrmont -> Sydney
// 12 Eden Street North Sydney -> North Sydney
// Pamela Avenue Peakhurst -> Banks

func queryLocation(lng, lat float64) string {
	rect := rtree.Point{lng, lat}.ToRect(1e-6)
	spatials := electorateTree.SearchIntersect(rect)
	for _, spatial := range spatials {
		electorate, ok := spatial.(*Electorate)
		if !ok {
			continue
		}
		for _, electoratePolygon := range electorate.polygons[highestZoomLevel] {
			if in := inside(shp.Point{X: lng, Y: lat}, *electoratePolygon.Polygon); in {
				return electorate.name
			}
		}
	}
	return ""
}

// queryPollingPlaces returns a point-feature-collection of clusters and
// polygons for a given list of comma separated electorate IDs.
func queryPollingPlaces(ids string) (*geojson.FeatureCollection, error) {
	var electorateIds []string
	for _, id := range strings.Split(ids, ",") {
		electorateIds = append(electorateIds, id)
	}
	// Not as large as the electore query response, still cachable so
	// sorting IDs.
	sort.Strings(electorateIds)
	fc := geojson.NewFeatureCollection()
	var points []shp.Point
	pplaceGroupIds := make(map[string]struct{})
	for _, id := range electorateIds {
		e := electorates[ElectorateID(id)]
		if e == nil {
			return nil, fmt.Errorf("Electorate not found for ID '%v'", id)
		}
		// Add features for polling places.
		for _, ep := range e.polygons[highestZoomLevel] {
			for _, pIndex := range ep.pollingPlaces {
				pollingPlace := pollingPlaces[pIndex]
				feature := pollingPlace.toFeature()
				// override minZoom, as it's relevant for the
				// client.
				feature.Properties["minZoom"] =
					pollingPlaceMinZoom[pIndex]
				fc.AddFeature(feature)
				points = append(points, shp.Point{X: pollingPlace.Lng, Y: pollingPlace.Lat})
			}
		}
		// Add features for clustering polling places.
		for _, pplaceGroup := range e.pplaceGrps {
			groupID := pplaceGroup.ID()
			if _, ok := pplaceGroupIds[groupID]; ok {
				continue
			}
			pplaceGroupIds[groupID] = struct{}{}
			fc.AddFeature(pplaceGroup.toFeatureWithID(groupID))
			points = append(points, shp.Point{X: pplaceGroup.Lng, Y: pplaceGroup.Lat})
		}
	}
	fcBbox := shp.BBoxFromPoints(points)
	fc.BoundingBox = []float64{fcBbox.MinX, fcBbox.MinY, fcBbox.MaxX, fcBbox.MaxY}
	return fc, nil
}
