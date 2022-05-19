# TODO: build static xerces-c-devel fmt-devel (needed for colorer plugin)
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
RUN echo "set(VCPKG_BUILD_TYPE $VCPKG_BUILD_TYPE)" >> $VCPKGDIR/triplets/x64-linux.cmake

RUN ./vcpkg install fmt
RUN ./vcpkg install spdlog
RUN ./vcpkg install xerces-c
RUN ./vcpkg install pcre
RUN ./vcpkg install zlib openssl
RUN ./vcpkg install libssh[core,zlib,openssl]
#RUN ./vcpkg install pcre2
RUN ./vcpkg install libarchive

RUN sudo dnf install -y libsmbclient-devel
RUN sudo dnf install -y libnfs-devel
RUN sudo dnf install -y neon-devel
#RUN sudo dnf install -y pcre-devel
#RUN sudo dnf install -y libssh-devel openssl-devel
#RUN sudo dnf install -y libarchive-devel

#RUN sudo dnf install -y uchardet-devel
#RUN sudo dnf install -y wxGTK3-devel


WORKDIR /build-far2l

COPY . $PREFIX/

#RUN ls -la /vcpkg/installed/x64-linux
RUN CMAKE_PREFIX_PATH=/vcpkg/installed/x64-linux \
   cmake $PREFIX -DEACP=no -DUSEUCD=no -DUSEWX=no #-DCOLORER=no
RUN make -j$(nproc)
RUN cpack

#CMD zip -qXr - far2l-nowx*.tar.gz
CMD cat far2l-nowx*.tar.gz

