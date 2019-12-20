FROM centos:centos8

WORKDIR /tmp

## install basic tools
RUN yum -y install yum-utils which tar wget autoconf automake\
           gcc gcc-c++ gcc-gfortran make

## build and install HDF5 library
WORKDIR /tmp/
RUN wget -q -O hdf5.tgz https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz; \
    tar -zxf hdf5.tgz; \
    cd /tmp/hdf5-1.10.5; \
    ./autogen.sh; \
    ./configure --prefix=/usr --enable-cxx; \
    make -j24; make install; \
    cd; \
    rm -rf /tmp/hdf5-1.10.5 /tmp/hdf5.tgz
