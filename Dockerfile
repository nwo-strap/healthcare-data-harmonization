FROM openjdk:18-slim-bullseye AS java-build-env

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        g++ \
        git \
        unzip \
        wget

# Install Go and protoc
RUN wget https://golang.org/dl/go1.18.1.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz && \
    wget https://github.com/protocolbuffers/protobuf/releases/download/v3.20.1/protoc-3.20.1-linux-x86_64.zip && \
    mkdir /usr/local/protoc && \
    unzip protoc-3.20.1-linux-x86_64.zip -d /usr/local/protoc

ENV PATH="$PATH:/usr/local/go/bin:/usr/local/protoc/bin"

# Build google whistle shared library
COPY  . /opt/gw
WORKDIR "/opt/gw/mapping_engine"
RUN chmod +x ./build_exports.sh && \
    ./build_exports.sh

# Copy shared library to a new base image.
FROM openjdk:18-slim-bullseye
COPY --from=java-build-env /opt/gw/mapping_engine/main/libgoogle_whistle.so /usr/lib
WORKDIR /home
