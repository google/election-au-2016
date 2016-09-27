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

import 'package:angular2/angular2.dart' show Injectable;
import 'package:intl/intl.dart';

@Injectable()
class Messages {
  String australian_election_results() =>
      Intl.message("Australian election results",
          name: "australian_election_results",
          args: [],
          desc: "Main title for the Australian election results site.");

  String current_australian_house_of_representatives() => Intl.message(
      "Current Australian House of Representatives",
      name: "current_australian_house_of_representatives",
      args: [],
      desc:
          "Main sidebar title when viewing the current House of Representatives state.");

  String election_results_will_be_updated_from(String date, String time) =>
      Intl.message("2016 election results will be updated from $date at $time",
          name: "election_results_will_be_updated_from",
          args: [date, time],
          desc:
              "The election results will begin to be updated from the given date and time. Fine detail under the side bar title.",
          examples: const {"date": "July 2nd, 2016", "time": "6:00pm"});

  String election_results_will_be_updated_from_aest(String date, String time) =>
      Intl.message(
          "2016 election results will be updated from $date at $time AEST",
          name: "election_results_will_be_updated_from_aest",
          args: [date, time],
          desc:
              "The election results will begin to be updated from the given date and time. Fine detail under the side bar title.",
          examples: const {"date": "July 2nd, 2016", "time": "6:00pm"});

  String party() => Intl.message("Party",
      name: "party",
      args: [],
      desc:
          "Which political party is it (ie, 'labor', 'liberal'). Column heading.");

  String seats() => Intl.message("Seats",
      name: "seats",
      args: [],
      desc:
          "The number of seats in parliament a party might have. Column heading.");

  String leader() => Intl.message("Leader",
      name: "leader",
      args: [],
      desc: "Leader of the political party. Column heading.");

  String privacy_and_terms() => Intl.message("Privacy and Terms",
      name: "privacy_and_terms",
      args: [],
      desc: "Privacy and terms web link text. Shown on the sidebar.");

  String more_parties() => Intl.message("More Parties",
      name: "more_parties",
      args: [],
      desc:
          "Bottom of a list to expand and see more parties currently not shown.");

  String n_needed_for_majority(String n) => Intl.message(
      "$n needed for majority",
      name: "n_needed_for_majority",
      args: [n],
      desc:
          "The number of seats needed for said party to have the majority of seats in parliament and win the election. Shown above the half-donut visualization on the sidebar.",
      examples: const {"n": "150"});

  String search_address_suburb_or_electorate() => Intl.message(
      "Search address, suburb or electorate",
      name: "search_address_suburb_or_electorate",
      args: [],
      desc:
          "Default search string for guiding the user in searching, without the option of searching for a candidate. Contained in a text element at the top of the sidebar.");

  String search_address_suburb_electorate_or_candidate() => Intl.message(
      "Search address, suburb, electorate or candidate",
      name: "search_address_suburb_electorate_or_candidate",
      args: [],
      desc:
          "Default search string for guiding the user in searching. Contained in a text element at the top of the sidebar.");

  String last_updated(String date, String time) => Intl.message(
      "Last updated $date at $time",
      name: "last_updated",
      args: [date, time],
      desc:
          "Text shown under the sidebar title to indicate the freshness of data.",
      examples: const {"date": "July 2nd, 2016", "time": "6:00pm"});

  String share_link() => Intl.message("Share Link",
      name: "share_link",
      args: [],
      desc:
          "Sidebar button text to share the current viewport with someone else.");

  String embed_map() => Intl.message("Embed Map",
      name: "embed_map",
      args: [],
      desc:
          "Sidebar button text to generate embed HTML to put this map on another website.");

  String source(String src) => Intl.message("Source: $src",
      name: "source",
      args: [src],
      desc:
          "Indicates where some data was sourced from for attribution purposes.",
      examples: const {"src": "Australian Electoral Commision (AEC)"});

  String electorate_of(String electorate) =>
      Intl.message("Electorate of $electorate",
          name: "electorate_of",
          args: [electorate],
          desc: "Sidebar title text when a given electorate is selected.",
          examples: const {"electorate": "Wentworth"});

  String ballot_paper() => Intl.message("2016 Ballot Paper",
      name: "ballot_paper",
      args: [],
      desc:
          "Sidebar sub-heading when an electorate is selected to indiate the candidates in ballot paper ordering.");

  String currently_party_seat(String party) => Intl.message(
      "Currently $party seat",
      name: "currently_party_seat",
      args: [party],
      desc:
          "Information text indicating which party current holds the seat. Shown when an electorate is selected.",
      examples: const {"party": "Liberal"});

  String currently_held_by(String party) => Intl.message(
      "Currently held by $party",
      name: "currently_held_by",
      args: [party],
      desc:
          "Information text indicating which party current holds the seat. Shown when an electorate is selected.",
      examples: const {"party": "Liberal"});

  String electorate_area(String area) => Intl.message("$area km²",
      name: "electorate_area",
      args: [area],
      desc:
          "Informat text indicate the area of the electorate. Shown when an electorate is selected.",
      examples: const {"area": "123"});

  String electors(String num) => Intl.message("$num electors",
      name: "electors",
      args: [num],
      desc:
          "Information text indicating the number of people who can vote in an area. Shown when an electorate is selected.",
      examples: const {"num": "123"});

  String more_candidates() => Intl.message("More candidates",
      name: "more_candidates",
      args: [],
      desc:
          "Show more candidates from list. Used to expand a list and show more items.");

  String polling_places() => Intl.message("Polling Places",
      name: "polling_places",
      args: [],
      desc:
          "Side bar sub-title with a list of places that are available for voting at");

  String showing_results(String from, String to) =>
      Intl.message("Showing results $from to $to",
          name: "showing_results",
          args: [from, to],
          desc: "Shown at the bottom of a list for pagination purposes",
          examples: const {"from": "1", "to": "10"});

  String accessible() => Intl.message("Accessible",
      name: "accessible",
      args: [],
      desc:
          "The polling place is able to be reached by people who have a disability.");

  String sausage_sizzle() => Intl.message("Sausage sizzle",
      name: "sausage_sizzle",
      args: [],
      desc:
          "The polling place has a sausage sizzle (cooked sausages) available.");

  String cake_stall() => Intl.message("Cake stall",
      name: "cake_stall",
      args: [],
      desc:
          "The polling place has a cake stall (place to buy cakes) available.");

  String more_details() => Intl.message("More details",
      name: "more_details",
      args: [],
      desc:
          "Show more details about the electorate. Text at the bottom of the summary for more detailed information.");

  String open_on(String date, String open_time, String close_time) => Intl.message(
      "Open on $date between $open_time and $close_time",
      name: "open_on",
      args: [date, open_time, close_time],
      desc:
          "This polling place is open on the given date between the given hours. Informational text.",
      examples: const {
        "date": "July 2nd, 2016",
        "open_time": "8am",
        "close_time": "6pm"
      });

  String directions() => Intl.message("Directions",
      name: "directions",
      args: [],
      desc:
          "Button text to launch navigation to get directions to the polling place.");

  String more_polling_places_in_this_electorate(String n) => Intl.message(
      "$n more polling places in this electorate",
      name: "more_polling_places_in_this_electorate",
      args: [n],
      desc:
          "There are a number more polling places where you can vote inside of the current electorate that is selected.",
      examples: const {"n": "123"});

  String seats_declared() => Intl.message("seats declared",
      name: "seats_declared",
      args: [],
      desc:
          "Text underneath a ratio indicating the current ratio of seats that have been declared.");

  String show_more() => Intl.message("Show more",
      name: "show_more",
      args: [],
      desc: "Expand a list to a more complete list of parties.");

  String show_less() => Intl.message("Show less",
      name: "show_less",
      args: [],
      desc: "Collapse a given list to limit the number of parties shown.");

  String electorate_results(String electorate) => Intl.message(
      "2016 $electorate Results",
      name: "electorate_results",
      args: [electorate],
      desc:
          "Heading indicating that the following content is results for the specified electorate",
      examples: const {"electorate": "Wentworth"});

  String preference_count(String number) => Intl.message(
      "$number preference count",
      name: "preference_count",
      args: [number],
      desc:
          "Heading. Following content is the count of first preference votes for each candidate",
      examples: const {"number": "1st"});

  String first_preference_count() => Intl.message("First Preference Count",
      name: "first_preference_count",
      args: [],
      desc:
          "Heading. Following content is the count of first preference votes for each candidate");

  String polling_stations_counted(String n, String m) => Intl.message(
      "$n out of $m polling stations counted.",
      name: "polling_stations_counted",
      args: [n, m],
      desc: "The number of polling stations that have had all votes counted",
      examples: const {"n": "56", "m": "57"});

  String percent_reporting(String percent) => Intl.message("$percent reporting",
      name: "percent_reporting",
      args: [percent],
      desc: "The percentage of first preference votes that have been counted",
      examples: const {"percent": "100%"});

  String votes() => Intl.message("Votes",
      name: "votes",
      args: [],
      desc:
          "Table heading indicating the number and percentage of votes for each candidate");

  String num_votes(String num) => Intl.message("$num votes",
      name: "num_votes",
      args: [num],
      desc:
          "The number of votes won by a given candidate. Includes preferences");

  String unknown_electorate() => Intl.message("Unknown electorate",
      name: "unknown_electorate",
      args: [],
      desc: "Searching for an electorate failed to return a valid electorate.");

  String unknown_seat() => Intl.message("Unknown seat",
      name: "unknown_seat",
      args: [],
      desc: "A seat that hasn't had a winner decided yet.");

  String first_results_expected_around(String date, String time) => Intl.message(
      "First results expected around $date at $time",
      name: "first_results_expected_around",
      args: [],
      desc:
          "The results will be first be updated at approximately July 2nd, 2016 at 6:00pm",
      examples: const {"date": "July 2nd, 2016", "time": "6:00pm"});

  String seat_declared() => Intl.message("Seat declared.",
      name: "seat_declared",
      args: [],
      desc: "This seat has been declared; a winner has been announced.");

  String candidate() => Intl.message("Candidate",
      name: "candidate",
      args: [],
      desc: "Table heading indicating the name of a candidate");

  String data_sourced_from(aec) => Intl.message("Data sourced from $aec 2016",
      name: "data_sourced_from",
      args: [aec],
      desc:
          "The data used on the map was sourced from the Australian Electoral Commission",
      examples: const {"aec": "Australian Electoral Commission"});

  String sausage_sizzle_data_provided_by(
          democracy_sausage, snag_votes) =>
      Intl.message(
          "Sausage sizzle data provided by $democracy_sausage and $snag_votes",
          name: "sausage_sizzle_data_provided_by",
          args: [democracy_sausage, snag_votes],
          desc:
              "The data used for sausage sizzle information was sourced from Democracy Sausage and Snag Votes",
          examples: const {
            "democracy_sausage": "Democracy Sausage",
            "snag_votes": "Snag Votes"
          });

  String historical_results_title() => Intl.message("2013 results",
      name: "historical_results_title",
      args: [],
      desc:
          "The title shown indicating that we are showing historical (2013) national election results.");

  String australian_house_of_representatives() => Intl.message(
      "Australian House of Representatives",
      name: "australian_house_of_representatives",
      args: [],
      desc:
          "The title shown indicating that we are showing the current election results for the house of representatives.");

  String wont_go_hungry() => Intl.message("You won't go hungry in line",
      name: "wont_go_hungry",
      args: [],
      desc: "The title shown for the sausage sizzle data indicator.");

  String live_sausage_data() =>
      Intl.message("Live sausage data coming hot off the barbie.",
          name: "live_sausage_data",
          args: [],
          desc: "The text shown for the sausage sizzle data indicator.");

  String we_could_not_find(String searchQuery) => Intl.message(
      "We could not find $searchQuery.",
      name: "we_could_not_find",
      args: [searchQuery],
      desc:
          "This is the initial text for a failed Search result, with the search term.",
      examples: const {"searchQuery": "This is a query with no results"});

  String make_sure_your_search() => Intl.message(
      "Make sure your search is spelled correctly. Try adding a city, or state.",
      name: "make_sure_your_search",
      args: [],
      desc:
          "This is an instruction shown on the failed Search result as an instruction for how to get results.");

  String more_google_search_results(String searchQuery) => Intl.message(
      "More Google search results for $searchQuery.",
      name: "more_google_search_results",
      args: [searchQuery],
      desc:
          "This is a link to Google Search for additional search results, for a given failed search term.",
      examples: const {"searchQuery": "This is a query with no results"});

  String close() => Intl.message("Close",
      name: "close",
      args: [],
      desc:
          "Alternative text for a cross icon which closes a modal dialog box.");

  String copy_link_from_address_bar() => Intl.message(
      "You can also copy the link from your browser's address bar.",
      name: "copy_link_from_address_bar",
      args: [],
      desc:
          "Content displayed in a modal popup indicating an alternative source of data.");

  String do_not_support_this_browser() => Intl.message(
      "We do not support this browser",
      name: "do_not_support_this_browser",
      args: [],
      desc:
          "The website that has been built does not load on the browser that is being used.");

  String click_to_zoom_in() => Intl.message("Click to zoom in",
      name: "click_to_zoom_in",
      args: [],
      desc:
          "This is a tooltip text that suggests users should click on the icon below your curser to zoom in and view it at a more magnified level");

  String open_external() => Intl.message("Open map in a new window",
      name: "open_external",
      args: [],
      desc:
          "Sidebar button text to allow users viewing an embedded version of  is election map to open it in a new page.");

  String send_feedback() => Intl.message("Send feedback",
      name: "send_feedback",
      args: [],
      desc:
          "This text describes a link to a Google Form questionnaire. The questionnaire allows users to submit feedback about their experience of using the website.");
}
