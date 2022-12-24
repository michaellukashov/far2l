# TODO: build static libsmbclient (needed for NetRocks-SMB)
# docker build -t far2l -f docker/Dockerfile --build-arg MAKEFLAGS_PARALLEL=-j4 .
# docker run --rm far2l cat /far2l-nowx-static.tar.gz > far2l-nowx-static.tar.gz

ARG MY_REGISTRY=

#FROM bitnami/debian-base-buildpack:latest
FROM ${MY_REGISTRY}debian:9.11-slim

ARG PREFIX=/build/far2l
ARG VCPKG_BUILD_TYPE=release
ARG MAKEFLAGS_PARALLEL="-j`nproc`"

ENV VCPKG_DEFAULT_TRIPLET=x64-linux
ENV VCPKGDIR=/build/vcpkg

RUN env DEBIAN_FRONTEND=noninteractive && apt-get update -y && apt-get upgrade -y && \
  apt-get install -y apt-utils apt-transport-https && \
  apt-get install -y binutils cmake make build-essential gcc g++ && \
  apt-get install -y perl cmake ninja-build && \
  apt-get install -y gawk m4 curl gettext pkgconf && \
  apt-get install -y zip unzip xz-utils tar patch git

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
  make ${MAKEFLAGS_PARALLEL} prefix=/usr && make prefix=/usr install

RUN CMAKE_ARCHIVE="cmake-3.25.1-linux-x86_64.tar.gz" && \
  CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v3.25.1/$CMAKE_ARCHIVE" && \
  curl -LO -C - "$CMAKE_URL" && \
  tar xf "$CMAKE_ARCHIVE" -C /usr --strip 1

# setup vcpkg
WORKDIR ${VCPKGDIR}
RUN git clone https://github.com/Microsoft/vcpkg.git --depth=1 .

RUN ./bootstrap-vcpkg.sh
RUN echo "set(VCPKG_BUILD_TYPE $VCPKG_BUILD_TYPE)" >> $VCPKGDIR/triplets/$VCPKG_DEFAULT_TRIPLET.cmake

# setup vcpkg libs
RUN ./vcpkg install zlib fmt spdlog xerces-c pcre
RUN ./vcpkg install libssh[core,mbedtls,zlib]
RUN ./vcpkg install libxml2 zstd liblzma libarchive uchardet
RUN ./vcpkg install openssl

WORKDIR /build/neon

# build neon library
RUN git clone --branch=0.32.4 --depth=1 https://github.com/notroj/neon.git . && \
  ./autogen.sh && \
	./configure --prefix=/build/neon --enable-static --disable-debug --with-ssl=openssl --with-libxml2 --with-libs=${VCPKGDIR}/installed/x64-linux && \
  make && make install-lib install-headers install-config

COPY . ${PREFIX}/

WORKDIR ${PREFIX}/build-far2l

RUN rm -rf ${PREFIX}/CMakeCache.txt ${PREFIX}/CMakeLists.txt.user 2>&1 && \
  cmake -G Ninja ${PREFIX} -DUSEWX=no \
  -DCMAKE_CXX_FLAGS="-DPIC -fPIE" \
  -DCMAKE_SHARED_LIBRARY_LINK_DYNAMIC_C_FLAGS="-fPIC -Os -static-libgcc -static-libstdc++ -pthread" \
  -DCMAKE_EXE_LINKER_FLAGS="-fPIC -Os -static-libgcc -static-libstdc++ -pthread" \
  -DCMAKE_MODULE_LINKER_FLAGS="-fPIC -pie -Os -static-libgcc -static-libstdc++ -pthread" \
  -Wno-dev -DOPT_USE_STATIC_EXT_LIBS=TRUE -DVCPKG_ROOT=${VCPKGDIR} \
  -DCMAKE_PREFIX_PATH=/build/neon \
  -DCMAKE_TOOLCHAIN_FILE=${VCPKGDIR}/scripts/buildsystems/vcpkg.cmake 

#RUN make far2l ${MAKEFLAGS_PARALLEL}
#RUN make install
RUN cmake --build . --target all -- ${MAKEFLAGS_PARALLEL}
RUN cmake --build . --target install
#cmake -G Ninja
# RUN ninja -v
RUN cpack
RUN cat far2l-nowx-*.tar.gz > /far2l-nowx-static.tar.gz

WORKDIR /
# Install the entry script
COPY ./docker/entry.sh /
ENTRYPOINT ["/entry.sh"]
# Just run `bash` if no other command is given
#CMD ["/bin/sh"]
