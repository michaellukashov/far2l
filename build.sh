#!/bin/sh

docker build -t far2l -f Dockerfile \
  --build-arg MAKE_ARGS=-j4 \
  .
