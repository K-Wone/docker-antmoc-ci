FROM alpine:latest

WORKDIR /tmp

## install basic tools
RUN apk add build-base\
            clang\
            make\
            autoconf\
            automake\
            which\
            wget

## use libgomp for clang
RUN ln -s $(find /usr -name omp.h | head -n1) /usr/include/omp.h; \
    ln -s /usr/lib/libgomp.so /usr/lib/libomp.so

## build and install HDF5 library
RUN wget -q -O hdf5.tgz https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz; \
    export CC=clang; \
    export CXX=clang++; \
    tar -zxf hdf5.tgz; \
    cd /tmp/hdf5-1.10.5; \
    ./autogen.sh; \
    ./configure --prefix=/usr --enable-cxx; \
    make -j24; make install; \
    cd; \
    rm -rf /tmp/hdf5-1.10.5 /tmp/hdf5.tgz
