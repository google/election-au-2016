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

import 'package:angular2/angular2.dart' show Component, Input;
import '../services/election_firebase_service.dart';

@Component(
    selector: 'candidateimg', templateUrl: 'candidate_image_component.html')
class CandidateImageComponent {
  String profileUrl;
  String initials;
  bool nullCandidate;

  @Input()
  set candidate(Candidate candidate) {
    nullCandidate = candidate == null;
    if (candidate == null) {
      return;
    }
    try {
      this.profileUrl = candidate.profileUrl;
      this.initials = candidate.initials;
    } catch (exception, stacktrace) {
      print("Couldn't prepare candidate image: $exception");
      print(stacktrace);
    }
  }
}
