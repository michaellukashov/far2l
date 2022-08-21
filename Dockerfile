# TODO: build static libsmbclient (needed for NetRocks-SMB)
# docker build -t far2l -f Dockerfile --build-arg MAKE_ARGS=-j4 .
# docker run --rm far2l cat /far2l-nowx-static.tar.gz > far2l-nowx-static.tar.gz

#FROM bitnami/debian-base-buildpack:latest
FROM debian:stable-slim
# FROM frolvlad/alpine-glibc

ARG PREFIX=/far2l
ARG VCPKG_DEFAULT_TRIPLET=x64-linux
ARG VCPKGDIR=/vcpkg
ARG VCPKG_BUILD_TYPE=release

RUN apt update -y && apt upgrade -y
RUN apt-get install -y apt-utils apt-transport-https
RUN apt-get install -y binutils cmake make build-essential gcc g++
#RUN apt-get install -y libstdc++6 libc6-compat
#RUN apt-get install -y gcc6 g++6
RUN apt-get install -y perl cmake ninja-build #build-base
RUN apt-get install -y linux-headers-$(uname -r) 
# RUN apt-get install -y zlib-static bzip2-static
RUN apt-get install -y gawk m4 curl gettext pkgconf git
#for libneon build
#RUN apt-get install -y zip unzip bzip2 xz-utils patch wget autoconf automake libtool gettext xmlto
RUN apt-get install -y zip unzip xz-utils tar patch

# setup vcpkg
#ENV VCPKG_FORCE_SYSTEM_BINARIES="1"

WORKDIR $VCPKGDIR
RUN git clone https://github.com/Microsoft/vcpkg.git --depth=1 .

RUN ./bootstrap-vcpkg.sh
RUN echo "set(VCPKG_BUILD_TYPE $VCPKG_BUILD_TYPE)" >> $VCPKGDIR/triplets/$VCPKG_DEFAULT_TRIPLET.cmake

# setup vcpkg libs
RUN ./vcpkg install fmt spdlog xerces-c pcre
RUN ./vcpkg install zlib openssl libssh[core,zlib,openssl]
RUN ./vcpkg install libxml2 zstd liblzma libarchive uchardet

# setup libs
#RUN apt-get install -y samba-dev
#RUN sudo apt-get install -y libnfs-devel neon-devel pcre-devel libssh-devel openssl-devel libarchive-devel uchardet-devel
RUN apt-get install -y libnfs-dev libneon27-dev
#RUN sudo apt-get install -y wxGTK3-devel
#RUN apt-get install -y ninja-build
RUN apt-get install -y autoconf automake libtool #xmlto

ARG MAKE_ARGS=

WORKDIR /build-far2l

COPY . $PREFIX/
#-DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++" \
RUN rm -rf $PREFIX/CMakeCache.txt 2>&1 && \
  cmake $PREFIX -DEACP=no -DUSEWX=no -DOPT_USE_STATIC_EXT_LIBS=TRUE \
  -DCMAKE_CXX_FLAGS="-D__MUSL__ -DPIC" \
  -DCMAKE_SHARED_LIBRARY_LINK_DYNAMIC_C_FLAGS="" \
  -DCMAKE_EXE_LINKER_FLAGS="-fPIC -Os -static-libgcc -static-libstdc++" \
  -Wno-dev -DVCPKG_ROOT=$VCPKGDIR
# -DCOLORER=no -DUSEUCD=no
RUN make ${MAKE_ARGS} #$(nproc)
RUN make install
#cmake -G Ninja
# RUN ninja -v
RUN cpack
RUN cat far2l-nowx-*.tar.gz > /far2l-nowx-static.tar.gz

#CMD zip -qXr - far2l-nowx*.tar.gz
#CMD cat far2l-nowx*.tar.gz

# Install the entry script
COPY entry.sh /
ENTRYPOINT ["/entry.sh"]
