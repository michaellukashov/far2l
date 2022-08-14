# TODO: build static libsmbclient (needed for NetRocks-SMB)
# docker build -t far2l -f Dockerfile .
# docker run --rm far2l > far2l-nowx-static.tar.gz
# docker run --rm far2l cat /build-far2l/far2l-nowx*.tar.gz > far2l-nowx-static.tar.gz

#FROM alpine:3.16.2
FROM frolvlad/alpine-glibc

ARG PREFIX=/far2l
ARG VCPKG_DEFAULT_TRIPLET=x64-linux
ARG VCPKGDIR=/vcpkg
ARG VCPKG_BUILD_TYPE=release
ARG MAKE_ARGS=

ENV VCPKG_FORCE_SYSTEM_BINARIES="1"

# RUN apk upgrade
RUN apk --no-cache add binutils cmake make libgcc musl-dev gcc g++
#RUN apk --no-cache add libstdc++6 libc6-compat
#RUN apk --no-cache add gcc6 g++6
RUN apk --no-cache add linux-headers perl cmake ninja #build-base
# RUN apk --no-cache add zlib-static bzip2-static

RUN apk --no-cache add gawk m4 curl gettext pkgconf git
#for libneon build
RUN apk --no-cache add zip unzip bzip2 xz patch wget which autoconf automake libtool gettext xmlto


# setup vcpkg
WORKDIR $VCPKGDIR
RUN git clone https://github.com/Microsoft/vcpkg.git --depth=1 .

RUN ./bootstrap-vcpkg.sh
RUN echo "set(VCPKG_BUILD_TYPE $VCPKG_BUILD_TYPE)" >> $VCPKGDIR/triplets/$VCPKG_DEFAULT_TRIPLET.cmake

# setup vcpkg libs
RUN ./vcpkg install fmt spdlog xerces-c pcre
RUN ./vcpkg install zlib openssl libssh[core,zlib,openssl]
RUN ./vcpkg install libxml2 zstd liblzma libarchive uchardet

# setup libs
#RUN apk --no-cache add samba-dev
#RUN sudo apk --no-cache add libnfs-devel neon-devel pcre-devel libssh-devel openssl-devel libarchive-devel uchardet-devel
#RUN sudo apk --no-cache add wxGTK3-devel
#RUN apk --no-cache add ninja-build

WORKDIR /build-far2l

COPY . $PREFIX/
#-DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++" \
RUN rm -rf $PREFIX/CMakeCache.txt 2>&1 && \
  cmake $PREFIX -DEACP=no -DUSEWX=no -DOPT_USE_STATIC_EXT_LIBS=TRUE \
  -DCMAKE_CXX_FLAGS=-D__MUSL__ \
  -DCMAKE_SHARED_LIBRARY_LINK_DYNAMIC_C_FLAGS="" \
  -DCMAKE_EXE_LINKER_FLAGS="-fPIC -Os -static -pthread" \
  -Wno-dev -DVCPKG_ROOT=$VCPKGDIR
# -DCOLORER=no -DUSEUCD=no
RUN make ${MAKE_ARGS} #$(nproc)
RUN make install
#cmake -G Ninja
# RUN ninja -v
RUN cpack

#CMD zip -qXr - far2l-nowx*.tar.gz
#CMD cat far2l-nowx*.tar.gz

# Install the entry script
COPY entry.sh /
ENTRYPOINT ["/entry.sh"]
