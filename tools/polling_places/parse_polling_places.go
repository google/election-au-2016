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

package main

// Parse the Polling Location data and generate a Go representation.
//
// Since the data is static (out of our control), and relatively small, we
// serve it directly from memory.
//
// Usage:
//
//  $ go build -v .
//  $ ./polling_places $data | gofmt > ../../go_backend/polling_places.go

import (
	"encoding/csv"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"strconv"
)

type PollingPlace struct {
	StateCode                        int
	StateAbbreviation                string
	DivisionName                     string
	DivisionId                       int
	DivisionCode                     int
	PrettyPrintName                  string
	PollingPlaceId                   int
	Status                           string
	PremisesName                     string
	Address1                         string
	Address2                         string
	Address3                         string
	AddressSuburb                    string
	AddressStateAbbreviation         string
	Postcode                         int
	AdvPremisesName                  string
	AdvAddress                       string
	AdvLocality                      string
	AdviceBoothLocation              string
	AdviceGateAccess                 string
	EntrancesDescription             string
	Lat                              float64
	Lng                              float64
	CensusCollectionDistrict         int
	WheelchairAccess                 string
	OrdinaryVoteEstimate             int
	DeclarationVoteEstimate          int
	NumberOrdinaryIssuingOfficers    int
	NumberDeclarationIssuingOfficers int
}

const (
	StateCo           int = 0
	StateAb           int = 1
	DivName           int = 2
	DivId             int = 3
	DivCo             int = 4
	PPName            int = 5
	Status            int = 6
	PremisesName      int = 7
	Address1          int = 8
	Address2          int = 9
	Address3          int = 10
	Locality          int = 11
	AddrStateAb       int = 12
	Postcode          int = 13
	PPId              int = 14
	AdvPremisesName   int = 15
	AdvAddress        int = 16
	AdvLocality       int = 17
	AdvBoothLocation  int = 18
	AdvGateAccess     int = 19
	EntrancesDesc     int = 20
	Lat               int = 21
	Long              int = 22
	CCD               int = 23
	WheelchairAccess  int = 24
	OrdVoteEst        int = 25
	DecVoteEst        int = 26
	NoOrdIssuingOff   int = 27
	NoOfDecIssuingOff int = 28
)

var (
	expectedHeader = []string{
		"StateCo",
		"StateAb",
		"DivName",
		"DivId",
		"DivCo",
		"PPName",
		"Status",
		"PremisesName",
		"Address1",
		"Address2",
		"Address3",
		"Locality",
		"AddrStateAb",
		"Postcode",
		"PPId",
		"AdvPremisesName",
		"AdvAddress",
		"AdvLocality",
		"AdvBoothLocation",
		"AdvGateAccess",
		"EntrancesDesc",
		"Lat",
		"Long",
		"CCD",
		"WheelchairAccess",
		"OrdVoteEst",
		"DecVoteEst",
		"NoOrdIssuingOff",
		"NoOfDecIssuingOff",
	}
)

func checkHeader(header []string) string {
	if len(header) != len(expectedHeader) {
		return fmt.Sprintf("Invalid header length: Expected %v, got %v", len(expectedHeader), len(header))
	}
	for i, _ := range header {
		if header[i] != expectedHeader[i] {
			return fmt.Sprintf("Invalid header %v: Expected %v, got %v", i, header[i], expectedHeader[i])
		}
	}
	return ""
}

func parseData(data io.Reader) ([]PollingPlace, []error) {
	reader := csv.NewReader(data)
	record, err := reader.Read()
	if err != nil {
		return nil, []error{err}
	}
	if err := checkHeader(record); err != "" {
		return nil, []error{errors.New(err)}
	}

	places := make([]PollingPlace, 0)
	errs := make([]error, 0)

	line := 1
	for {
		record, err := reader.Read()
		line++
		if err == io.EOF {
			break
		}
		if err != nil {
			errs = append(errs, err)
			continue
		}

		p := PollingPlace{}
		if p.StateCode, err = strconv.Atoi(record[StateCo]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid StateCo '%v'", line, record[StateCo])))
		}
		p.StateAbbreviation = record[StateAb]
		p.DivisionName = record[DivName]
		if p.DivisionId, err = strconv.Atoi(record[DivId]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid DivId '%v'", line, record[DivCo])))
		}
		if p.DivisionCode, err = strconv.Atoi(record[DivCo]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid DivCo '%v'", line, record[DivCo])))
		}
		p.PrettyPrintName = record[PPName]
		p.Status = record[Status]
		if p.Status == "Abolition" {
			continue
		}

		p.PremisesName = record[PremisesName]
		p.Address1 = record[Address1]
		p.Address2 = record[Address2]
		p.Address3 = record[Address3]
		p.AddressSuburb = record[Locality]
		p.AddressStateAbbreviation = record[AddrStateAb]
		if p.Postcode, err = strconv.Atoi(record[Postcode]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid Postcode '%v'", line, record[Postcode])))
		}
		if p.PollingPlaceId, err = strconv.Atoi(record[PPId]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid PPId '%v'", line, record[PPId])))
		}
		p.AdvPremisesName = record[AdvPremisesName]
		p.AdvAddress = record[AdvAddress]
		p.AdvLocality = record[AdvLocality]
		p.AdviceBoothLocation = record[AdvBoothLocation]
		p.AdviceGateAccess = record[AdvGateAccess]
		p.EntrancesDescription = record[EntrancesDesc]

		if record[Lat] == "" || record[Long] == "" {
			continue
		}
		if p.Lat, err = strconv.ParseFloat(record[Lat], 64); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid Lat '%v'", line, record[Lat])))
		}
		if p.Lng, err = strconv.ParseFloat(record[Long], 64); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid Long '%v'", line, record[Long])))
		}

		if p.CensusCollectionDistrict, err = strconv.Atoi(record[CCD]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid CCD '%v'", line, record[CCD])))
		}
		p.WheelchairAccess = record[WheelchairAccess]
		if p.OrdinaryVoteEstimate, err = strconv.Atoi(record[OrdVoteEst]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid WheelchairAccess '%v'", line, record[WheelchairAccess])))
		}
		if p.DeclarationVoteEstimate, err = strconv.Atoi(record[DecVoteEst]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid DecVoteEst '%v'", line, record[DecVoteEst])))
		}
		if p.NumberOrdinaryIssuingOfficers, err = strconv.Atoi(record[NoOrdIssuingOff]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid NoOrdIssuingOff '%v'", line, record[NoOrdIssuingOff])))
		}
		if p.NumberDeclarationIssuingOfficers, err = strconv.Atoi(record[NoOfDecIssuingOff]); err != nil {
			errs = append(errs, errors.New(fmt.Sprintf("Line %v: Invalid NoOfDecIssuingOff '%v'", line, record[NoOfDecIssuingOff])))
		}

		places = append(places, p)
	}

	return places, errs
}

func writePollingPlaces(places []PollingPlace) {
	fmt.Println(`
package election

// AUTOGENERATED: Use tools/polling_places/parse_polling_places.go to regenerate.

type PollingPlace struct {
	StateCode                        int
	StateAbbreviation                string
	DivisionName                     string
	DivisionId                       int
	DivisionCode                     int
	PrettyPrintName                  string
	PollingPlaceId                   int
	Status                           string
	PremisesName                     string
	Address1                         string
	Address2                         string
	Address3                         string
	AddressSuburb                    string
	AddressStateAbbreviation         string
	Postcode                         int
	AdvPremisesName			 string
	AdvAddress			 string
        AdvLocality			 string
	AdviceBoothLocation              string
	AdviceGateAccess                 string
	EntrancesDescription             string
	Lat                              float64
	Lng                              float64
	CensusCollectionDistrict         int
	WheelchairAccess                 string
	OrdinaryVoteEstimate             int
	DeclarationVoteEstimate          int
	NumberOrdinaryIssuingOfficers    int
	NumberDeclarationIssuingOfficers int
}

var (
	pollingPlaces = []PollingPlace {
`)
	for _, p := range places {
		fmt.Printf("\tPollingPlace { %v, %q, %q, %v, %v, %q, %v, %q, %q, %q, %q, %q, %q, %q, %v, %q, %q, %q, %q, %q, %q, %v, %v, %v, %q, %v, %v, %v, %v},\n",
			p.StateCode, p.StateAbbreviation, p.DivisionName, p.DivisionId, p.DivisionCode, p.PrettyPrintName, p.PollingPlaceId, p.Status, p.PremisesName,
			p.Address1, p.Address2, p.Address3, p.AddressSuburb, p.AddressStateAbbreviation, p.Postcode, p.AdvPremisesName, p.AdvAddress, p.AdvLocality,
			p.AdviceBoothLocation, p.AdviceGateAccess, p.EntrancesDescription, p.Lat, p.Lng, p.CensusCollectionDistrict, p.WheelchairAccess, p.OrdinaryVoteEstimate,
			p.DeclarationVoteEstimate, p.NumberOrdinaryIssuingOfficers, p.NumberDeclarationIssuingOfficers)
	}
	fmt.Println(`
})
`)
}

func main() {
	flag.Parse()
	args := flag.Args()
	if len(args) < 1 {
		fmt.Println("Expected input filename")
		os.Exit(1)
	}

	file := args[0]
	data, err := os.Open(file)
	if err != nil {
		fmt.Println("Unable to read file '%v'", file)
		os.Exit(2)
	}
	defer data.Close()

	places, errors := parseData(data)
	if len(errors) > 0 {
		fmt.Println("Errors found:")
		for _, err := range errors {
			fmt.Println("  %v", err)
		}
		os.Exit(3)
	}
	writePollingPlaces(places)
}
