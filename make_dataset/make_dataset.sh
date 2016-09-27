#!/bin/sh

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

set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Building datasetpipeline container"
pushd $DIR/docker
docker build -t datasetpipeline .
popd
# debug: add -it after "run" below to allow Ctrl+C etc.
docker run --rm \
    -v $DIR/geodata:/geodata \
    -v $DIR/transform_simplify:/transform_simplify \
    datasetpipeline /transform_simplify/transform_simplify.sh
