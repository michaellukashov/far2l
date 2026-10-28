# Build recipe for the Anthropic OSS Scanner (https://red.anthropic.com/oss-scanner).
# The scanner builds this file with the far2l repository as the build context, then
# re-runs it without network access for auditing, so everything must be fetched here.
FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates build-essential cmake ninja-build pkg-config git python3 \
      libwxgtk3.2-dev libx11-dev libxi-dev \
      libuchardet-dev libxml2-dev \
      libarchive-dev libssh-dev \
    && rm -rf /var/lib/apt/lists/*

# Scanner contract: the checkout lives inside the image, at /src
COPY . /src
WORKDIR /src

# Build the same way the maintainers do (see ./Dockerfile at the repo root), but with
# debug info and frame pointers. The result lands in /src/build/install: the far2l
# binary plus the built plugins under install/Plugins. The Python plugin is left
# disabled (-DPYTHON=yes would add it); the wxWidgets backend is enabled.
RUN cmake -S /src -B /src/build -G Ninja \
      -DUSEWX=yes -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_C_FLAGS="-g -fno-omit-frame-pointer" \
      -DCMAKE_CXX_FLAGS="-g -fno-omit-frame-pointer" \
    && cmake --build /src/build -j"$(nproc)"

# Cheap sanity check; do not let a failure abort the image build.
RUN cd /src/build \
    && (test -x install/far2l && echo "far2l binary OK" || echo "WARNING: far2l binary missing") \
    && (ctest --output-on-failure -j"$(nproc)" --timeout 300 || echo "WARNING: ctest reported failures")
