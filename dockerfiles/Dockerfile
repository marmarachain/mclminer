# ===========================
# Stage 1: MCL Builder
# ===========================
FROM ubuntu:18.04 AS builder
LABEL maintainer="abdulkadir@marmara.io"

WORKDIR /marmarachain

ARG BUILD_PACKAGES="libevent-dev libboost-system-dev libboost-filesystem-dev \
    libboost-chrono-dev libboost-program-options-dev curl libboost-test-dev \
    libboost-thread-dev build-essential pkg-config libc6-dev m4 g++-multilib \
    autoconf libtool ncurses-dev python3-zmq zlib1g-dev wget bsdmainutils \
    automake cmake clang libsodium-dev libcurl4-gnutls-dev libssl-dev git unzip python jq"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y $BUILD_PACKAGES

RUN git clone https://github.com/marmarachain/marmara.git -b development --single-branch

# MCL build
RUN marmara/zcutil/build.sh -j$(nproc)

# ===========================
# Stage 2: Runtime Container
# ===========================
FROM ubuntu:18.04
LABEL maintainer="abdulkadir@marmara.io"

# dependencies
RUN apt-get update && \
    apt-get install -y \
    default-libmysqlclient-dev build-essential git cmake pkg-config \
    libsodium-dev libcurl4-gnutls-dev libnghttp2-dev librtmp-dev \
    libssh2-1 libssh2-1-dev libldap2-dev libidn11-dev libpsl-dev libkrb5-dev \
    libgomp1 wget curl nano && \
    rm -rf /var/lib/apt/lists/*

# Copy marmara binaries from builder
COPY --from=builder /marmarachain/marmara/src/marmarad /usr/local/bin/
COPY --from=builder /marmarachain/marmara/src/marmara-cli /usr/local/bin/

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ARG GROUP_ID=1000
ARG USER_ID=1000
RUN addgroup --gid ${GROUP_ID} usergroup && \
    adduser --disabled-password --gecos '' --uid ${USER_ID} --gid ${GROUP_ID} mclminer && \
    chown -R mclminer:usergroup /home/mclminer


COPY fetch-params.sh /home/mclminer/fetch-params.sh

RUN chown mclminer:usergroup /home/mclminer/fetch-params.sh && \
    chmod +x /home/mclminer/fetch-params.sh

USER mclminer
WORKDIR /home/mclminer

# Clone repo and Compile
RUN git clone https://github.com/marmarachain/yiimp-stratum-equihash.git && \
    cd yiimp-stratum-equihash && \
    git checkout mcl && \
    make -C iniparser/ -j$(nproc) && \
    make -C algos/ -j$(nproc) && \
    make -C sha3 -j$(nproc) && \
    make -f Makefile -j$(nproc)

EXPOSE 33825 8888

ENTRYPOINT ["entrypoint.sh"]
