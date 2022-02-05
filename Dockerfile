# TODO: build static libsmbclient (needed for NetRocks-SMB)
# sudo docker build -t far2l -f Dockerfile .
# sudo docker run --rm far2l > far2l-nowx.tar.gz

FROM fedora:32

ARG PREFIX=/far2l
ARG VCPKG_DEFAULT_TRIPLET=x64-linux
ARG VCPKGDIR=/vcpkg
ARG VCPKG_BUILD_TYPE=release

RUN sudo dnf update -y
RUN sudo dnf install -y gawk m4 gcc g++ git zip perl cmake

WORKDIR $VCPKGDIR
RUN git clone https://github.com/Microsoft/vcpkg.git --depth=1 .

RUN ./bootstrap-vcpkg.sh
#RUN ./vcpkg install xerces-c fmt --triplet=x64-linux
#RUN ./vcpkg install spdlog openssl libssh libarchive
#--triplet=x64-linux
RUN echo "set(VCPKG_BUILD_TYPE $VCPKG_BUILD_TYPE)" >> $VCPKGDIR/triplets/$VCPKG_DEFAULT_TRIPLET.cmake

RUN ./vcpkg install fmt spdlog xerces-c pcre
RUN ./vcpkg install zlib openssl
RUN ./vcpkg install libssh[core,zlib,openssl]
RUN ./vcpkg install pcre2
RUN ./vcpkg install libarchive uchardet

RUN sudo dnf install -y libsmbclient-devel
#RUN sudo dnf install -y libnfs-devel
#RUN sudo dnf install -y neon-devel
#RUN sudo dnf install -y pcre-devel
#RUN sudo dnf install -y libssh-devel openssl-devel
#RUN sudo dnf install -y libarchive-devel

#RUN sudo dnf install -y uchardet-devel
#RUN sudo dnf install -y wxGTK3-devel


WORKDIR /build-far2l

COPY . $PREFIX/

#RUN ls -la /vcpkg/installed/x64-linux
RUN cmake $PREFIX -DEACP=no -DUSEWX=no -DOPT_USE_STATIC_EXT_LIBS=TRUE -Wno-dev -DVCPKG_PARENT_DIR=$VCPKGDIR/.. #-DVCPKG_ROOT=$VCPKGDIR -DCOLORER=no -DUSEUCD=no -DCMAKE_PREFIX_PATH=$VCPKGDIR/installed/x64-linux
RUN make -j$(nproc)
RUN cpack

#CMD zip -qXr - far2l-nowx*.tar.gz
CMD cat far2l-nowx*.tar.gz

