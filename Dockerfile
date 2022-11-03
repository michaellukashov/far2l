# TODO: build static libsmbclient (needed for NetRocks-SMB)
# docker build -t far2l -f Dockerfile --build-arg MAKEFLAGS_PARALLEL=-j4 .
# docker run --rm far2l cat /far2l-nowx-static.tar.gz > far2l-nowx-static.tar.gz

ARG MY_REGISTRY=

#FROM bitnami/debian-base-buildpack:latest
FROM ${MY_REGISTRY}debian:9.11-slim

ARG PREFIX=/build/far2l
ARG VCPKG_BUILD_TYPE=release
ARG MAKEFLAGS_PARALLEL=""

ENV VCPKG_DEFAULT_TRIPLET=x64-linux
ENV VCPKGDIR=/build/vcpkg

RUN env DEBIAN_FRONTEND=noninteractive && apt-get update -y && apt-get upgrade -y && \
  apt-get install -y apt-utils apt-transport-https && \
  apt-get install -y binutils cmake make build-essential gcc g++ && \
  apt-get install -y perl cmake ninja-build && \
  apt-get install -y gawk m4 curl gettext pkgconf git && \
  apt-get install -y zip unzip xz-utils tar patch

# for libneon
RUN env DEBIAN_FRONTEND=noninteractive && apt-get install -y autoconf automake libtool
# for git
RUN env DEBIAN_FRONTEND=noninteractive && apt-get install -y libssl-dev libcurl4-openssl-dev zlib1g-dev libexpat-dev
# for NetRocks-NFS
#RUN apt-get install -y samba-dev
RUN env DEBIAN_FRONTEND=noninteractive && apt-get install -y libnfs-dev
#RUN sudo apt-get install -y wxGTK3-devel

# setup git
WORKDIR /build/git
RUN git clone https://github.com/git/git.git --depth=1 . && \
  make -j ${MAKEFLAGS_PARALLEL} prefix=/usr && make prefix=/usr install

# setup vcpkg
WORKDIR ${VCPKGDIR}
RUN git clone https://github.com/Microsoft/vcpkg.git . #--depth=1 .

RUN ./bootstrap-vcpkg.sh
# RUN echo "set(VCPKG_BUILD_TYPE $VCPKG_BUILD_TYPE)" >> $VCPKGDIR/triplets/$VCPKG_DEFAULT_TRIPLET.cmake

# setup vcpkg libs
RUN ./vcpkg install fmt
RUN ./vcpkg install spdlog xerces-c 
RUN ./vcpkg install pcre
RUN ./vcpkg install zlib
#RUN ./vcpkg install mbedtls
RUN ./vcpkg install libssh[core,mbedtls,zlib]
RUN ./vcpkg install libxml2 zstd liblzma libarchive uchardet
RUN ./vcpkg install openssl

COPY . ${PREFIX}/

WORKDIR ${PREFIX}/build-far2l

#-DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++" \
RUN rm -rf ${PREFIX}/CMakeCache.txt ${PREFIX}/CMakeLists.txt.user 2>&1 && \
  ${VCPKGDIR}/downloads/tools/cmake-3.24.0-linux/cmake-3.24.0-linux-x86_64/bin/cmake ${PREFIX} -DUSEWX=no \
  -DCMAKE_CXX_FLAGS="-DPIC" \
  -DCMAKE_SHARED_LIBRARY_LINK_DYNAMIC_C_FLAGS="" \
  -DCMAKE_EXE_LINKER_FLAGS="-fPIC -Os -static-libgcc -static-libstdc++" \
  -DCMAKE_SHARED_LINKER_FLAGS="-fPIC -Os -static-libgcc -static-libstdc++" \
  -Wno-dev -DOPT_USE_STATIC_EXT_LIBS=TRUE -DVCPKG_ROOT=${VCPKGDIR} \
  -DCMAKE_TOOLCHAIN_FILE=${VCPKGDIR}/scripts/buildsystems/vcpkg.cmake 

RUN make far2l ${MAKEFLAGS_PARALLEL} #$(nproc)
RUN make install
#cmake -G Ninja
# RUN ninja -v
RUN cpack
RUN cat far2l-nowx-*.tar.gz > /far2l-nowx-static.tar.gz

# Install the entry script
COPY entry.sh /
ENTRYPOINT ["/entry.sh"]
# Just run `bash` if no other command is given
#CMD ["/bin/sh"]
