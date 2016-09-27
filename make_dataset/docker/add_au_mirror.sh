#!/bin/bash

# Copyright 2016 Google Inc. All rights reserved.
#
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
# file except in compliance with the License. You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under
# the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific language governing
# permissions and limitations under the License.

MIRROR="http://au.archive.ubuntu.com/ubuntu/"
VERSION="xenial"
cat - /etc/apt/sources.list <<END >/etc/apt/sources.list.new && mv /etc/apt/sources.list.new /etc/apt/sources.list
deb $MIRROR $VERSION main restricted
deb $MIRROR $VERSION-security main restricted
deb $MIRROR $VERSION-updates main restricted
deb $MIRROR $VERSION universe multiverse
deb $MIRROR $VERSION-security universe multiverse
deb $MIRROR $VERSION-updates universe multiverse
END
