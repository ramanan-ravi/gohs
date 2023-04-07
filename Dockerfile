ARG UBUNTU_VERSION=22.04

FROM ubuntu:${UBUNTU_VERSION}

ARG GO_VERSION=1.20.3
ARG HYPERSCAN_VERSION=5.4.1
ARG PCRE_VERSION=8.45

# Install dependencies

ENV DEBIAN_FRONTEND noninteractive
RUN <<EOT bash
    apt-get update 
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        libboost-dev \
        libbz2-dev \
        libpcap-dev \
        ninja-build \
        pkg-config \
        python2.7 \
        ragel \
        wget \
        zlib1g-dev 
    rm -rf /var/lib/apt/lists/*
EOT

# Install golang

ADD https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz /go${GO_VERSION}.tar.gz
RUN <<EOT bash
    rm -rf /usr/local/go 
    tar -C /usr/local -xzf /go${GO_VERSION}.tar.gz
    rm /go${GO_VERSION}.tar.gz
EOT

ENV PATH=/usr/local/go/bin:${PATH}

# Download Hyperscan

ENV HYPERSCAN_DIR=/hyperscan

ADD https://github.com/intel/hyperscan/archive/refs/tags/v${HYPERSCAN_VERSION}.tar.gz /hyperscan-v${HYPERSCAN_VERSION}.tar.gz
RUN <<EOT bash 
    mkdir ${HYPERSCAN_DIR}
    tar xf /hyperscan-v${HYPERSCAN_VERSION}.tar.gz -C ${HYPERSCAN_DIR} --strip-components=1
    rm /hyperscan-v${HYPERSCAN_VERSION}.tar.gz
EOT

ADD https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz/download /pcre-${PCRE_VERSION}.tar.gz
RUN <<EOT bash  
    mkdir ${HYPERSCAN_DIR}/pcre
    tar xf /pcre-${PCRE_VERSION}.tar.gz -C ${HYPERSCAN_DIR}/pcre --strip-components=1 
    rm /pcre-${PCRE_VERSION}.tar.gz
EOT

# Install Hyperscan

ENV INSTALL_DIR=/usr/local

RUN <<EOT bash 
    mkdir ${HYPERSCAN_DIR}/build 
    cd ${HYPERSCAN_DIR}/build 
    cmake -G Ninja -DBUILD_STATIC_LIBS=on -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} ${HYPERSCAN_DIR} 
    ninja 
    ninja install 
    mv ${HYPERSCAN_DIR}/build/lib/lib*.a ${INSTALL_DIR}/lib/     
EOT

ENV PKG_CONFIG_PATH=${INSTALL_DIR}/lib/pkgconfig

# Add gohs code

ADD . /gohs/

WORKDIR /gohs
ENTRYPOINT ["/usr/local/go/bin/go"]
CMD ["test", "-v", "./..."]
