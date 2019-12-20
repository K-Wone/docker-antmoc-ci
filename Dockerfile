FROM centos:7.6.1810

WORKDIR /tmp

## install basic tools
RUN yum -y install yum-utils centos-release-scl\
                   which tar wget autoconf automake

## install gcc-8 from the Software Collections
RUN yum -y install devtoolset-8-gcc\
                   devtoolset-8-gcc-c++\
                   devtoolset-8-gcc-gfortran\
                   devtoolset-8-make

## build and install HDF5 library and compiler wrapper
WORKDIR /tmp/
RUN wget -q -O hdf5.tgz https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz; \
    tar -zxf hdf5.tgz; \
    cd /tmp/hdf5-1.10.5; \
    source /opt/rh/devtoolset-8/enable; \
    ./autogen.sh; \
    ./configure --prefix=/usr --enable-cxx; \
    make -j24; make install; \
    cd; rm -rf /tmp/hdf5-1.10.5 /tmp/hdf5.tgz
