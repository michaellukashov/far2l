#!/usr/bin/env bash

set -x
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]] ; then set -o xtrace ; fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# echo script_dir: ${script_dir}
project_dir=$(dirname "${script_dir}")
# echo project_dir: ${project_dir}
pushd "${project_dir}"

docker build -t far2l -f docker/Dockerfile \
  --build-arg MAKEFLAGS_PARALLEL=-j4 \
  .

# get built archive
docker run --rm far2l cat /far2l-nowx-static.tar.gz > far2l-nowx-static.tar.gz

popd
