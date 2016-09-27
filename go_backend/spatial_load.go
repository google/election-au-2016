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
	"bytes"
	"fmt"
	"log"
	"math"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	rtree "github.com/dhconnelly/rtreego"
	shp "github.com/jonas-p/go-shp"
	cluster "github.com/smira/go-point-clustering"
)

// DataFolder is the name of the folder we expect to find the shapefiles under zoomlevel bucket
// subfolders.
const DataFolder = "dist/national_elb"

func initSpatial() {
	initZoomBuckets()
	initElectorates()
	// TODO: the 'ByElectorates' and 'ByPolygon' clustering methods below
	// require a single rtree of polling places.  We could simplify
	// initPollingPlaces for this purpose, as it's no longer used for
	// viewport queries.
	initPollingPlaces()
	// Note order is important, as in the new clustering scheme polling
	// places rely on electorate data (shapefiles etc.) to be loaded.
	initPollingPlacesByElectorates()
	clusterPollingPlacesByPolygon()
	unclusterSmallIdenticalClusters()
}

// ZoomLevel means one of a set of consumer viewport's zoom level when viewing
// maps.  It is used in this context to choose a level of detail for
// electorate's polygons.  Higher zoom means a greater level detail.
type ZoomLevel int

// ElectorateID is a unique identifier for an electorate in the system.
type ElectorateID string

// ElectoratePolygon contains a single polygon (out of possibly many) for an
// electorate, as well as GIS details such as centroid and GIS ID.
type ElectoratePolygon struct {
	*shp.Polygon
	centLat  float32
	centLong float32
	gisid    string
	// We use this for rough calculations and comparisons, not for
	// presenting data to the user. (unlike areaSqkm)
	area          float32
	pollingPlaces []int
}

// Electorate is a derivative from the Australian Election Committee definition
// of an electorate, including its polygons as defined in the shapefile, an ID
// and a few other attributes.
type Electorate struct {
	id         ElectorateID
	name       string
	state      string
	areaSqkm   float32
	bbox       *shp.Box
	polygons   map[ZoomLevel][]*ElectoratePolygon
	pplaceGrps []pollingPlaceGroup
}

// Bounds returns the bounding box of an electorate multi polygon.
func (e Electorate) Bounds() *rtree.Rect {
	bounds, err := BboxToRect(e.bbox)
	if err != nil {
		log.Panic(err)
	}
	return bounds
}

func (e *Electorate) addPolygon(z ZoomLevel, ep *ElectoratePolygon) {
	e.polygons[z] = append(e.polygons[z], ep)
	e.bbox.Extend(ep.BBox())
}

var electorateTree *rtree.Rtree
var polplaceTrees map[int]*rtree.Rtree = make(map[int]*rtree.Rtree)

// A mapping from electorate ID to Electorate.
var electorates map[ElectorateID]*Electorate

// A list of different zoom levels that we have geometries at. A value of '9'
// looks good at zoom level '9' and below. These are determined at startup time
// based on the files available in the national_elb directory.
var zoomBuckets []ZoomLevel

var highestZoomLevel ZoomLevel

func initZoomBuckets() {
	dirnames, err := filepath.Glob(filepath.Join(DataFolder, "/*"))
	if err != nil {
		log.Fatal(err)
	}
	var zooms []int
	for _, dir := range dirnames {
		zoom, err := strconv.Atoi(filepath.Base(dir))
		if err != nil {
			log.Printf("Ignoring directory `%s`; it doesn't represent a zoom level.\n", dir)
			continue
		}
		zooms = append(zooms, zoom)
	}
	// zoomBuckets are sorted ascending.
	sort.Ints(zooms)
	for _, z := range zooms {
		zoomBuckets = append(zoomBuckets, ZoomLevel(z))
	}
	highestZoomLevel = zoomBuckets[len(zoomBuckets)-1]
}

// groundResolution indicates the distance in km on the ground that’s
// represented by a single pixel in the map.
func groundResolutionByLatAndZoom(lat float64, zoom int) float64 {
	// number of pixels for the width of the (square) world map in web
	// mercator.  i.e. for zoom level 0, this would give 256 pixels.
	numPixels := math.Pow(2, float64(8+zoom))
	// We return earth's circumference (at given latitude) divided by
	// number of pixels for the map's width.  Note: EarthRadius is given in
	// km.
	return cos(lat) * 2 * math.Pi * EarthRadius / numPixels
}

type pollingPlaceGroup struct {
	pollingPlaceIndices []int
	Lng                 float64
	Lat                 float64
	minZoom             int
	divisionName        ElectorateID
}

// Bounds for a polling place group is calculated similarly to a single polling
// place point.
func (pg pollingPlaceGroup) Bounds() *rtree.Rect {
	return rtree.Point{pg.Lng, pg.Lat}.ToRect(1e-6)
}

type pollingPlaceSpatial struct {
	PollingPlace
	index int
}

// Bounds returns the bounding box of a polling place point.
// Rtree implementation requires a bounding box.
func (p pollingPlaceSpatial) Bounds() *rtree.Rect {
	return rtree.Point{p.Lng, p.Lat}.ToRect(1e-6)
}

// pollingPlaceMinZoom is a mapping between a polling place index and the
// minimum zoom level at which the polling place should be shown by the client:
// at this zoom level (and at higher levels) the polling place is not clustered
// and should be shown individually.
var pollingPlaceMinZoom = make(map[int]int)

const uluruLatitude float64 = -25.353954
const pollingPlaceImageWidth = 48

func getClusteringRadiusAndMinClusterSize(zoom int) (float64, int) {
	// For highest zoom level, consider polling places 10 meters apart as
	// the same.  Allow for groups of size 2.
	if zoom == MinZoomLevelToShowUngroupedPollingPlaces {
		return 0.01, 2
	}
	groundResolution := groundResolutionByLatAndZoom(uluruLatitude, zoom)
	// Multiply ground resolution per pixel by the width (in pixels).. +
	// "manually adjust".
	clusteringRadius := groundResolution * pollingPlaceImageWidth * 1.5
	// Set min group size to 3
	return clusteringRadius, 3
}

// truncatePoint truncates the values of p.X and p.Y to e decimal places.
func truncatePoint(p cluster.Point, e int) {
	exp := math.Pow10(e)
	// Not the best way to truncate to a given number of decimal place, but
	// good enough..
	p[0] = math.Trunc(p[0]*exp) / exp
	p[1] = math.Trunc(p[1]*exp) / exp
}

func initPollingPlacesByElectorates() {
	initialGroupingByElectorates := make(map[ElectorateID][]int)
	for i, p := range pollingPlaces {
		id := ElectorateID(strings.ToLower(p.DivisionName))
		initialGroupingByElectorates[id] = append(initialGroupingByElectorates[id], i)
	}
	// Sanity checking:
	if len(initialGroupingByElectorates) != len(electorates) {
		log.Fatalf("Polling places have %v electorate IDs, electorates have %v IDs.", len(initialGroupingByElectorates), len(electorates))
	}
	for id, pIndices := range initialGroupingByElectorates {
		e, ok := electorates[id]
		// Further sanity check.
		if !ok {
			log.Fatalf("Electorate ID '%v' is present in polling places but not in electorates.", id)
		}
		for _, ep := range e.polygons[highestZoomLevel] {
			var pollingPlaceByPolygon []int
			for _, pIndex := range pIndices {
				p := pollingPlaces[pIndex]
				// TODO: Some polling places will be positioned
				// outside of their electorate (not in any of
				// the polygons).  In this approach we throw
				// them away, because we assume that they are
				// 'appointment' locations such as Sydney's
				// Town Hall.
				if inside(shp.Point{X: p.Lng, Y: p.Lat}, *ep.Polygon) {
					pollingPlaceByPolygon = append(pollingPlaceByPolygon, pIndex)
				}
			}
			ep.pollingPlaces = pollingPlaceByPolygon
		}
	}
}

func addNearbyPollingPlaces(
	pollingPlaceGroups []pollingPlaceGroup, pointMap map[int]int, clusteringRadius float64) {

	// The received pointMap is pointList-index to pollingPlaces-index. In
	// this method we mostly work with pollingPlaces-index so we introduce
	// the reverse map for this purpose.
	pollingPlaceMap := make(map[int]int)
	for plIndex, pIndex := range pointMap {
		pollingPlaceMap[pIndex] = plIndex
	}
	// Use the highest zoom level, to ensure we get most polling places
	// individually.
	pollingPlaceRTree := polplaceTrees[MinZoomLevelToShowUngroupedPollingPlaces]
	for i, group := range pollingPlaceGroups {
		// "Some relation" (in km) between the zoom level's clustering
		// radius and the number of points currently in the cluster.
		relationKm := clusteringRadius *
			float64(len(group.pollingPlaceIndices)) / 20
		// "Some formula" converting the above relation (km) to
		// 'tolerance' which is measured in degrees.  To make life
		// easier, if we were to consider only latitudes, 111.2 km == 1
		// degree.
		tolerance := relationKm / 111.2
		centroidRect := rtree.Point{group.Lng, group.Lat}.ToRect(tolerance)
		spatials := pollingPlaceRTree.SearchIntersect(centroidRect)
		var indicesToConsider []int
		for _, s := range spatials {
			// Optional: only take those polling places that are at
			// a given radius (or less).  Currently taking
			// everything rtree gave back which is some latlng
			// rectangle.
			if ppg, ok := s.(pollingPlaceGroup); ok {
				// Optional: only take the first. Currently
				// taking all.
				indicesToConsider = append(indicesToConsider,
					ppg.pollingPlaceIndices...)
				continue
			}
			if pps, ok := s.(pollingPlaceSpatial); ok {
				indicesToConsider = append(indicesToConsider, pps.index)
			}
		}
		for _, pIndex := range indicesToConsider {
			// If the point is not in the map it was already
			// "taken" into a different cluster, OR it is not a
			// part of the original pointList (probably not a part
			// of the electorate polygon).
			// -> So if it's in the map we can add it to our point
			// cluster.
			if plIndex, ok := pollingPlaceMap[pIndex]; ok {
				// NOTE can't set group.pollingPlaceIndices
				// because it's a copy of the slice item.
				pollingPlaceGroups[i].pollingPlaceIndices = append(pollingPlaceGroups[i].pollingPlaceIndices, pIndex)
				// We delete the point from both maps to update
				// the caller. The remaining points in pointMap
				// are the polling places which are deemed to
				// remain unclustered.
				delete(pollingPlaceMap, pIndex)
				delete(pointMap, plIndex)
			}
		}
	}
}

func clusterPollingPlacesByPolygon() {
	// TODO we know that at highest zoom level, the clustering is done
	// mostly to de-dupe but this isn't currently considered here.
	// ^ See current viewport query implementation. This may be done in the
	// client since it has the recommended minimum zoom for each cluster.
	zoom := MaxZoomLevelToIgnorePollingPlaces + 1
	for ; zoom <= MinZoomLevelToShowUngroupedPollingPlaces; zoom++ {
		clusteringRadius, minClusterSize := getClusteringRadiusAndMinClusterSize(zoom)
		var polygonsTooSmallForThisZoom []*ElectoratePolygon
		for _, e := range electorates {
			var pollingPlaceGroups []pollingPlaceGroup
			for _, ep := range e.polygons[highestZoomLevel] {
				if float64(ep.area) < 2*clusteringRadius*clusteringRadius {
					polygonsTooSmallForThisZoom = append(polygonsTooSmallForThisZoom, ep)
					continue
				}
				var pointList cluster.PointList
				pointMap := make(map[int]int)
				for _, pIndex := range ep.pollingPlaces {
					if _, ok := pollingPlaceMinZoom[pIndex]; ok {
						continue
					}
					pplace := pollingPlaces[pIndex]
					pointList = append(pointList, cluster.Point{pplace.Lng, pplace.Lat})
					// Record all polygon-associated
					// polling places (mapping from DBScan
					// required pointList index to real
					// index).
					pointMap[len(pointList)] = pIndex
				}
				clusters, _ := cluster.DBScan(pointList, clusteringRadius, minClusterSize)
				for _, clstr := range clusters {
					centroid, _, _ := clstr.CentroidAndBounds(pointList)
					truncatePoint(centroid, 5)
					pIndices := make([]int, len(clstr.Points))
					for i, plIndex := range clstr.Points {
						pIndex := pointMap[plIndex]
						pIndices[i] = pIndex
						// Remove clustered points
						delete(pointMap, plIndex)
					}
					pollingPlaceGroup := pollingPlaceGroup{
						pollingPlaceIndices: pIndices,
						Lng:                 centroid[0],
						Lat:                 centroid[1],
						minZoom:             zoom,
						divisionName:        e.id,
					}
					pollingPlaceGroups = append(pollingPlaceGroups, pollingPlaceGroup)
				}
				// Since clusters' centroids are artificial, we
				// merge individual nearby polling places
				// relevant cluster. This reduces noise around
				// the centroid.
				addNearbyPollingPlaces(pollingPlaceGroups, pointMap, clusteringRadius)
				// Remaining keys in pointMap are polling
				// places which were not clustered. Set their
				// zoom now.
				for _, pIndex := range pointMap {
					if _, ok := pollingPlaceMinZoom[pIndex]; ok {
						continue
					}
					pollingPlaceMinZoom[pIndex] = zoom
				}
			}
			e.pplaceGrps = append(e.pplaceGrps, pollingPlaceGroups...)
		}
		// Now cluster the too-small polygons too, potentially together.
		var pointList2 cluster.PointList
		pointMap2 := make(map[int]int)
		for _, ep := range polygonsTooSmallForThisZoom {
			for _, pIndex := range ep.pollingPlaces {
				pplace := pollingPlaces[pIndex]
				pointList2 = append(pointList2, cluster.Point{pplace.Lng, pplace.Lat})
				pointMap2[len(pointList2)] = pIndex
			}
		}
		clusters, _ := cluster.DBScan(pointList2, clusteringRadius, minClusterSize)
		var pollingPlaceGroups []pollingPlaceGroup
		for _, clstr := range clusters {
			centroid, _, _ := clstr.CentroidAndBounds(pointList2)
			truncatePoint(centroid, 5)
			pIndices := make([]int, len(clstr.Points))
			electoratesForCluster := make(map[ElectorateID]struct{})
			for i, plIndex := range clstr.Points {
				// First map back to the polling places index
				// (rather than pointList2 index)
				pIndex := pointMap2[plIndex]
				// Since a polling place (for a given zoom
				// level) is either clustered or not clustered,
				// and if clustered occurs only once at that
				// cluster, we can now safely remove it from
				// the map
				delete(pointMap2, plIndex)
				// The proper indices will be used in the
				// polling place group.
				pIndices[i] = pIndex
				// Find the electorate ID associated with this
				// polling place.
				eid := ElectorateID(strings.ToLower(pollingPlaces[pIndex].DivisionName))
				// Finally, since the polling place group is
				// possibly shared between several electorates
				// (depending on the actual points that were in
				// fact clustered in), need to record those

				// TODO: this isn't as useful as originally
				// thought. May make more sense to associate
				// cluster with its centroid location (polygon
				// which contains it), which BTW can actually
				// land in a different polygons to the ones
				// used for clustering. Or at sea.
				electoratesForCluster[eid] = struct{}{}
			}
			divisionName := ElectorateID("")
			// Only record a division name for a cluster if it's
			// the only one.
			if len(electoratesForCluster) == 1 {
				for eid := range electoratesForCluster {
					divisionName = eid
				}
			}
			pollingPlaceGroup := pollingPlaceGroup{
				pollingPlaceIndices: pIndices,
				Lng:                 centroid[0],
				Lat:                 centroid[1],
				minZoom:             zoom,
				divisionName:        divisionName,
			}
			pollingPlaceGroups = append(pollingPlaceGroups, pollingPlaceGroup)
			// The polling place group we created now needs to be
			// assigned to all electorates we've identified.
			for eid := range electoratesForCluster {
				electorates[eid].pplaceGrps = append(electorates[eid].pplaceGrps, pollingPlaceGroup)
			}
		}
		addNearbyPollingPlaces(pollingPlaceGroups, pointMap2, clusteringRadius)
		// Since we removed all polling places that were clustered at
		// this zoom level, the remaining ones are non-clustered, so we
		// can now mark their zoom level.
		for _, pIndex := range pointMap2 {
			if _, ok := pollingPlaceMinZoom[pIndex]; ok {
				continue
			}
			pollingPlaceMinZoom[pIndex] = zoom
		}
	}
	// debug:
	// var ids []string
	// for id := range electorates {
	// 	ids = append(ids, string(id))
	// }
	// // print in order to allow quick spot checking for errors.
	// sort.Strings(ids)
	// for _, id := range ids {
	// 	log.Printf("For electorate %v, found %v clusters.", id, len(electorates[ElectorateID(id)].pplaceGrps))
	// }
}

func unclusterSmallIdenticalClusters() {
	for _, e := range electorates {
		seenGroup := make(map[string]struct{})
		var removeGroups []int
		for i, group := range e.pplaceGrps {
			groupID := group.IDNoZoom()
			if _, ok := seenGroup[groupID]; !ok {
				seenGroup[groupID] = struct{}{}
				continue
			}
			if len(group.pollingPlaceIndices) > 9 {
				continue
			}
			unclusterInNextZoomLevel := true
			for _, pIndex := range group.pollingPlaceIndices {
				if pollingPlaceMinZoom[pIndex] != group.minZoom+1 {
					unclusterInNextZoomLevel = false
					break
				}
			}
			if !unclusterInNextZoomLevel {
				continue
			}
			removeGroups = append(removeGroups, i)
		}
		// We need descending order to allow running deletes.
		sort.Sort(sort.Reverse(sort.IntSlice(removeGroups)))
		for _, i := range removeGroups {
			removeGroup := e.pplaceGrps[i]
			// Introduce a new zoom level (should be current-1) to
			// polling places in this group.
			for _, pIndex := range removeGroup.pollingPlaceIndices {
				pollingPlaceMinZoom[pIndex] = removeGroup.minZoom
			}
			// Remove group from electorate groups.
			e.pplaceGrps = append(e.pplaceGrps[:i], e.pplaceGrps[i+1:]...)
			// debug:
			// log.Printf("Removed group [%v] at zoom level %v as it existed at level %v", removeGroup.IDNoZoom(), removeGroup.minZoom, removeGroup.minZoom-1)
		}
	}
}

func initPollingPlaces() {
	pointList := make(cluster.PointList, len(pollingPlaces))
	for i, p := range pollingPlaces {
		pointList[i] = cluster.Point{p.Lng, p.Lat}
	}
	for zoom := MaxZoomLevelToIgnorePollingPlaces + 1; zoom <= MinZoomLevelToShowUngroupedPollingPlaces; zoom++ {
		clusteringRadius, minClusterSize := getClusteringRadiusAndMinClusterSize(zoom)
		clusters, _ := cluster.DBScan(pointList, clusteringRadius, minClusterSize)
		var pollingPlaceGroups []pollingPlaceGroup
		clusteredPollingPlaces := make(map[int]struct{})
		for _, clstr := range clusters {
			center, _, _ := clstr.CentroidAndBounds(pointList)
			truncatePoint(center, 5)
			for _, index := range clstr.Points {
				clusteredPollingPlaces[index] = struct{}{}
			}
			pollingPlaceGroups = append(pollingPlaceGroups, pollingPlaceGroup{
				pollingPlaceIndices: clstr.Points,
				Lng:                 center[0],
				Lat:                 center[1],
			})
		}
		polplaceTree := rtree.NewTree(2, 100, 200)
		for _, pg := range pollingPlaceGroups {
			polplaceTree.Insert(pg)
		}
		for i, p := range pollingPlaces {
			if _, ok := clusteredPollingPlaces[i]; ok {
				continue
			}
			pps := pollingPlaceSpatial{
				PollingPlace: p,
				index:        i,
			}
			polplaceTree.Insert(pps)
		}
		polplaceTrees[zoom] = polplaceTree
	}
}

func initElectorates() {
	electorates = make(map[ElectorateID]*Electorate)
	// For loading, use the highest level of detail first (descending).
	for i := len(zoomBuckets) - 1; i >= 0; i-- {
		zoomLevel := zoomBuckets[i]
		log.Printf("Loading zoom level %v", zoomLevel)
		zoomdir := fmt.Sprint(zoomLevel)
		filenames, err := filepath.Glob(filepath.Join(DataFolder, zoomdir, "*.shp"))
		if err != nil {
			log.Fatal(err)
			return
		}
		for _, filename := range filenames {
			err = loadElectorates(filename, zoomLevel, electorates)
			if err != nil {
				log.Fatal(err)
			}
		}
	}
	// Create the rtree with 2 dimensions and some room for > 100 geometries.
	electorateTree = rtree.NewTree(2, 16, 32)
	for _, e := range electorates {
		electorateTree.Insert(e)
	}
	log.Printf("Electorate map has %v entries\n", len(electorates))

}

func readZeroTerminatedString(s string) string {
	n := bytes.IndexByte([]byte(s), 0)
	if n < 0 {
		return s
	}
	return string(s[:n])
}

func loadElectorates(filename string, z ZoomLevel, electorates map[ElectorateID]*Electorate) error {
	r, err := shp.Open(filename)
	if err != nil {
		return err
	}
	defer r.Close()

	// fields from the attribute table (DBF)
	fields := map[string]int{
		"gis_id": 0,
		// area_sqkm is the original AEC provided area of an electorate
		// (a multi-polygon)
		"area_sqkm": 0,
		// area is the mapshaper (ogr) calculated area of a single
		// polygon. It is currently calculated in WGS-84, which is
		// isn't a good projection to calculate areas in general.  We
		// use this for rough calculations and comparisons, not for
		// presenting data to the user.
		"area":      0,
		"sortname":  0,
		"state":     0,
		"cent_long": 0,
		"cent_lat":  0,
	}
	for k, f := range r.Fields() {
		fieldName := readZeroTerminatedString(string(f.Name[:]))
		// debug:
		// log.Printf("%v: %v", k, fieldName)
		if _, ok := fields[fieldName]; ok {
			fields[fieldName] = k
		}
	}
	// debug:
	// log.Printf("Loading %v, found fields: %v", filename, fields)

	// loop through all features in the shapefile
	// debug (name verification)
	// ids := make(map[ElectorateID]struct{})
	for r.Next() {
		index, shape := r.Shape()

		// The shp.Polygon struct (as well shapefile defintion) is actually a multipolygon.
		// https://www.ibm.com/support/knowledgecenter/SSGU8G_12.1.0/com.ibm.spatial.doc/ids_spat_293.htm
		// Update: decided to split input to single polygons.
		polygon, ok := shape.(*shp.Polygon)
		if !ok {
			// The shape is null (or not a polygon, which we don't expect so we treat as null).
			log.Printf("On index %v, expected polygon geometry but found: %T", index, shape)
			continue
		}
		centLat, err := strconv.ParseFloat(r.ReadAttribute(index, fields["cent_lat"]), 32)
		if err != nil {
			return fmt.Errorf("On index %v, expected float centroid latitude in field cent_lat", index)
		}
		centLong, err := strconv.ParseFloat(r.ReadAttribute(index, fields["cent_long"]), 32)
		if err != nil {
			return fmt.Errorf("On index %v, expected float centroid longitude in field cent_long", index)
		}
		area, err := strconv.ParseFloat(r.ReadAttribute(index, fields["area"]), 32)
		if err != nil {
			return fmt.Errorf("Expected area field of type float")
		}
		// Currently ignored, it may be useful later.
		gisid := readZeroTerminatedString(r.ReadAttribute(index, fields["gis_id"]))
		name := readZeroTerminatedString(r.ReadAttribute(index, fields["sortname"]))
		if name == "Mcpherson" {
			name = "McPherson"
		}
		if name == "Mcmillan" {
			name = "McMillan"
		}
		// DB's sortname (lowercased) will be used as ID.
		id := ElectorateID(strings.ToLower(name))
		// Debug: name verification of electorates. They are not all properly Title-Cased.
		// if z == highestZoomLevel {
		// 	if _, ok := ids[id]; !ok {
		// 		ids[id] = struct{}{}
		// 		log.Printf("Electorate: %v", name)
		// 	}
		// }
		// Debug: sanity check sydney's bounding box is {{151.171465,-33.924332}, {151.23088,-33.849776}}
		// if z == highestZoomLevel && id == ElectorateID("sydney") && inside(shp.Point{X: 151.2152967, Y: -33.8567844}, *polygon) {
		// 	log.Printf("Sydney polygon, bbox is: %v", polygon.BBox())
		// }
		electoratePolygon := &ElectoratePolygon{
			Polygon:  polygon,
			centLat:  float32(centLat),
			centLong: float32(centLong),
			area:     float32(area),
			gisid:    gisid,
		}
		// Check if we've seen this electorate previously.
		if electorate, ok := electorates[id]; ok {
			// If we did, we have no interest in the rest of the metadata about the electorate.
			// Take the polygon for this zoom level and move to the next feature.
			electorate.addPolygon(z, electoratePolygon)
			continue
		}
		areaSqkm, err := strconv.ParseFloat(r.ReadAttribute(index, fields["area_sqkm"]), 32)
		if err != nil {
			return fmt.Errorf("Expected area field of type float")
		}
		polygons := map[ZoomLevel][]*ElectoratePolygon{
			z: []*ElectoratePolygon{electoratePolygon},
		}
		// BBox() creates a copy, so that we could make changes to our
		// copy.
		bbox := electoratePolygon.BBox()
		electorate := &Electorate{
			id:       id,
			name:     name,
			state:    readZeroTerminatedString(r.ReadAttribute(index, fields["state"])),
			areaSqkm: float32(areaSqkm),
			bbox:     &bbox,
			polygons: polygons,
		}
		electorates[id] = electorate
	}
	return nil
}
