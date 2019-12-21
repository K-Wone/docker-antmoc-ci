FROM alpine:latest

WORKDIR /tmp

## install basic tools
RUN apk add alpine-sdk which wget autoconf automake\
            python3 py3-lxml

## install gcovr
RUN pip3 install gcovr

## build and install HDF5 library
RUN wget -q -O hdf5.tgz https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz; \
    tar -zxf hdf5.tgz; \
    cd /tmp/hdf5-1.10.5; \
    ./autogen.sh; \
    ./configure --prefix=/usr --enable-cxx; \
    make -j24; make install; \
    cd; \
    rm -rf /tmp/hdf5-1.10.5 /tmp/hdf5.tgz
