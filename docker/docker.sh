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

far2l_build_x86_64_alpine()
{
pushd "${project_dir}"

docker build -t far2l:alpine -f docker/Dockerfile.alpine \
  --build-arg MAKEFLAGS_PARALLEL=-j`nproc` \
  .

# get built archive
docker run --rm far2l:alpine cat /far2l-nowx-static.tar.gz > far2l-nowx-static-alpine.tar.gz

popd
}

far2l_build_aarch64_alpine()
{
pushd "${project_dir}"

docker build -t far2l:aarch64-alpine -f docker/Dockerfile.aarch64-alpine \
  --build-arg MAKEFLAGS_PARALLEL=-j`nproc` \
  .

# get built archive
docker run --rm far2l:aarch64-alpine cat /far2l-nowx-static.tar.gz > far2l-nowx-static-aarch64-alpine.tar.gz

popd
}


far2l_build_debian()
{
pushd "${project_dir}"

docker build -t far2l:debian -f docker/Dockerfile \
  --build-arg MAKEFLAGS_PARALLEL=-j`nproc` \
  .

# get built archive
docker run --rm far2l:debian cat /far2l-nowx-static.tar.gz > far2l-nowx-static-debian.tar.gz

popd
}

far2l_login()
{
pushd "${project_dir}"

docker run -it --rm --name=far2l \
	--mount type=bind,source=${PWD},target=/far2l \
	far2l \
	bash -i

popd
}

if [[ "${1-}" == "build" ]] ; then
  far2l_build_debian
  exit
fi

if [[ "${1-}" == "build-x86_64-alpine" ]] ; then
  far2l_build_x86_64_alpine
  exit
fi

if [[ "${1-}" == "build-aarch64-alpine" ]] ; then
  far2l_build_aarch64_alpine
  exit
fi

if [[ "${1-}" == "login" ]] ; then
  far2l_login
  exit
fi

# far2l_build_x86_64_alpine
far2l_build_debian
