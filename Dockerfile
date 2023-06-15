# Use a base image with the desired Linux distribution and version 
FROM ubuntu:latest

# Install dependencies and required packages 
RUN apt-get update && \
    apt-get install -y \
        build-essential \
	git \
        gfortran \
        libblas-dev \
        liblapack-dev \
        libopenmpi-dev \
        openmpi-bin \
	libfftw3-dev \
	libopenblas-dev \
	libint-dev \
	libxc-dev \
        wget \
	python3-pip python3-dev \
        zlib1g-dev \
	cmake \
	libxml2-dev \
	libtiff5-dev \
	libboost-dev \
	&& ln -s /usr/bin/pyton3 /usr/local/bin \
	&& rm -rf /var/lib/apt/lists/*

# Download CP2K source code
RUN git clone --recursive https://github.com/cp2k/cp2k.git 

# Set the working directory
WORKDIR /cp2k

# Build CP2K
#WORKDIR /cp2k/tools/toolchain
RUN cd tools/toolchain && ls \
    && /bin/bash install_cp2k_toolchain.sh --with-fftw=system --with-openblas=system --with-libint=system --mpi-mode=no

RUN cd /cp2k/arch \
    && cp ../tools/toolchain/install/arch/* . \
    && cd .. \
    && make -j 4 ARCH=local VERSION="ssmp" \
    && make -j$(nproc)  ARCH=local VERSION="ssmp" libcp2k

ENV PATH="/cp2k/exe/local:${PATH}"

# Build GROMACS
RUN git clone https://gitlab.com/gromacs/gromacs.git /gromacs

WORKDIR /gromacs
RUN mkdir build && cd build \
    && cmake .. -DGMX_MPI=off -DGMX_DOUBLE=off -DBUILD_SHARED_LIBS=off -DGMXAPI=off -DGMX_INSTALL_NBLIB_API=off -DGMX_FFT_LIBRARY=fftw3 -DGMX_EXTERNAL_BLAS=on -DGMX_EXTERNAL_LAPACK=on -DGMX_CP2K=on -DCP2K_DIR=/cp2k/lib/local/ssmp \
    && make -j$(nproc) \
    && make install

# Set environment variables
ENV LD_LIBRARY_PATH="/usr/local/gromacs/lib:${LD_LIBRARY_PATH}"
ENV PATH="/usr/local/gromacs/bin:${PATH}"

# Set the entrypoint command
#ENTRYPOINT ["cp2k.ssmp"]

# Set default command arguments if needed 
#CMD ["-h"]
CMD ["bash"]

