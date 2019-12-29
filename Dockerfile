# the latest HDF5 image compiled with GCC
FROM leavesask/hdf5:1.10.5-gcc

USER root

WORKDIR /tmp

# install basic tools
RUN apk add --no-cache \
            make \
            python3 \
            py3-lxml

# install gcovr
RUN pip3 install gcovr
