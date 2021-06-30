#!/bin/bash

./cmakeclean.sh

unset GATOR_DISABLE

export CC=gcc
export CXX=g++
export CXXFLAGS="-O3"
export FFLAGS="-O3"

export CXXFLAGS="-O3"

cmake -DYAKL_ARCH="CUDA"                             \
      -DYAKL_CUDA_FLAGS="-O3 -arch sm_35 -ccbin g++ -DTHRUST_IGNORE_CUB_VERSION_CHECK" \
      ..

