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

// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a es locale. All the
// messages from the main program should be duplicated here with the same
// function name.

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

final _keepAnalysisHappy = Intl.defaultLocale;

class MessageLookup extends MessageLookupByLibrary {
  get localeName => 'es';

  static currently_held_by(party) => "Ocupado actualmente por: ${party}";

  static currently_party_seat(party) => "Escaño actual del partido ${party}";

  static data_sourced_from(aec) => "Datos de ${aec} (2016)";

  static election_results_will_be_updated_from(date, time) =>
      "Los resultados de las elecciones de 2016 se actualizarán a partir del ${date} a las ${time}";

  static electorate_area(area) => "${area} km²";

  static electorate_of(electorate) => "Electorado de ${electorate}";

  static electorate_results(electorate) => "Resultados de 2016 (${electorate})";

  static electors(num) => "${num} votantes";

  static first_results_expected_around(date, time) =>
      "Se estima que los primeros resultados se sabrán el ${date} a las ${time}.";

  static last_updated(date, time) =>
      "Última actualización el ${date} a las ${time}";

  static more_google_search_results(searchQuery) =>
      "Más resultados de ${searchQuery} de la Búsqueda de Google.";

  static more_polling_places_in_this_electorate(n) =>
      "Hay ${n} colegios electorales más en este electorado";

  static n_needed_for_majority(n) =>
      "Se necesitan ${n} escaños para obtener la mayoría";

  static num_votes(num) => "${num} votos";

  static open_on(date, open_time, close_time) =>
      "Abre el ${date} de ${open_time} a ${close_time}";

  static percent_reporting(percent) => "${percent} escrutado";

  static polling_stations_counted(n, m) =>
      "El recuento se ha completado en ${n} de ${m} colegios electorales.";

  static preference_count(number) =>
      "Recuento de votos de ${number} preferencia";

  static sausage_sizzle_data_provided_by(democracy_sausage, snag_votes) =>
      "Datos de la venta de perritos calientes proporcionados por ${democracy_sausage} y ${snag_votes}";

  static showing_results(from, to) => "Mostrando resultados ${from} de ${to}";

  static source(src) => "Fuente: ${src}";

  static we_could_not_find(searchQuery) =>
      "No se han encontrado resultados de ${searchQuery}.";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => {
        "accessible": MessageLookupByLibrary
            .simpleMessage("Adaptado para personas con discapacidad"),
        "australian_election_results": MessageLookupByLibrary
            .simpleMessage("Resultados de las elecciones australianas"),
        "australian_house_of_representatives": MessageLookupByLibrary
            .simpleMessage("Cámara de Representantes de Australia"),
        "ballot_paper":
            MessageLookupByLibrary.simpleMessage("Papeleta electoral de 2016"),
        "cake_stall":
            MessageLookupByLibrary.simpleMessage("Puesto de pasteles"),
        "candidate": MessageLookupByLibrary.simpleMessage("Candidato"),
        "click_to_zoom_in":
            MessageLookupByLibrary.simpleMessage("Hacer clic para ampliar"),
        "close": MessageLookupByLibrary.simpleMessage("Cerrar"),
        "copy_link_from_address_bar": MessageLookupByLibrary.simpleMessage(
            "También puedes copiar el enlace de la barra de direcciones del navegador."),
        "current_australian_house_of_representatives": MessageLookupByLibrary
            .simpleMessage("Cámara de Representantes de Australia actual"),
        "currently_held_by": currently_held_by,
        "currently_party_seat": currently_party_seat,
        "data_sourced_from": data_sourced_from,
        "directions": MessageLookupByLibrary.simpleMessage("Indicaciones"),
        "do_not_support_this_browser": MessageLookupByLibrary
            .simpleMessage("Este navegador no es compatible con el sitio web"),
        "election_results_will_be_updated_from":
            election_results_will_be_updated_from,
        "electorate_area": electorate_area,
        "electorate_of": electorate_of,
        "electorate_results": electorate_results,
        "electors": electors,
        "embed_map": MessageLookupByLibrary.simpleMessage("Insertar mapa"),
        "first_preference_count": MessageLookupByLibrary
            .simpleMessage("Recuento de votos de primera preferencia"),
        "first_results_expected_around": first_results_expected_around,
        "historical_results_title":
            MessageLookupByLibrary.simpleMessage("Resultados de 2013"),
        "last_updated": last_updated,
        "leader": MessageLookupByLibrary.simpleMessage("Líder"),
        "live_sausage_data": MessageLookupByLibrary.simpleMessage(
            "Datos de la venta de perritos calientes recién salidos de la barbacoa."),
        "make_sure_your_search": MessageLookupByLibrary.simpleMessage(
            "Comprueba que la búsqueda se haya escrito correctamente. Prueba a añadir una ciudad o un estado."),
        "more_candidates":
            MessageLookupByLibrary.simpleMessage("Más candidatos"),
        "more_details": MessageLookupByLibrary.simpleMessage("Más detalles"),
        "more_google_search_results": more_google_search_results,
        "more_parties": MessageLookupByLibrary.simpleMessage("Más partidos"),
        "more_polling_places_in_this_electorate":
            more_polling_places_in_this_electorate,
        "n_needed_for_majority": n_needed_for_majority,
        "num_votes": num_votes,
        "open_on": open_on,
        "party": MessageLookupByLibrary.simpleMessage("Partido"),
        "percent_reporting": percent_reporting,
        "polling_places":
            MessageLookupByLibrary.simpleMessage("Colegios electorales"),
        "polling_stations_counted": polling_stations_counted,
        "preference_count": preference_count,
        "privacy_and_terms":
            MessageLookupByLibrary.simpleMessage("Privacidad y condiciones"),
        "sausage_sizzle": MessageLookupByLibrary
            .simpleMessage("Venta de perritos calientes para recaudar fondos"),
        "sausage_sizzle_data_provided_by": sausage_sizzle_data_provided_by,
        "search_address_suburb_electorate_or_candidate": MessageLookupByLibrary
            .simpleMessage("Buscar dirección, barrio, electorado o candidato"),
        "search_address_suburb_or_electorate": MessageLookupByLibrary
            .simpleMessage("Buscar dirección, barrio o electorado"),
        "seat_declared":
            MessageLookupByLibrary.simpleMessage("Escaño declarado"),
        "seats": MessageLookupByLibrary.simpleMessage("Escaños"),
        "seats_declared":
            MessageLookupByLibrary.simpleMessage("escaños declarados"),
        "send_feedback":
            MessageLookupByLibrary.simpleMessage("Enviar comentarios"),
        "share_link": MessageLookupByLibrary.simpleMessage("Compartir enlace"),
        "show_less": MessageLookupByLibrary.simpleMessage("Mostrar menos"),
        "show_more": MessageLookupByLibrary.simpleMessage("Mostrar más"),
        "showing_results": showing_results,
        "source": source,
        "unknown_electorate":
            MessageLookupByLibrary.simpleMessage("Electorado desconocido"),
        "unknown_seat":
            MessageLookupByLibrary.simpleMessage("Escaño desconocido"),
        "votes": MessageLookupByLibrary.simpleMessage("Votos"),
        "we_could_not_find": we_could_not_find,
        "wont_go_hungry":
            MessageLookupByLibrary.simpleMessage("No pases hambre en la cola")
      };
}
