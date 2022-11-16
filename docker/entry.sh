#!/bin/sh

#cmake -DEACP=no -DUSEWX=no -DOPT_USE_STATIC_EXT_LIBS=TRUE -S /far2l -B /build-far2l -DVCPKG_ROOT=/vcpkg
#cmake --build /build-far2l -- -j4
#cmake --build /build-far2l --target install

exec "$@"
