FROM debian:testing-slim

ARG LDC_VER=1.26.0

ENV COMPILER=ldc \
    COMPILER_VERSION=$LDC_VER

RUN apt-get update && \
    apt-get --no-install-recommends install -y \
    ca-certificates \
    cmake \
    ninja-build \
    curl \
    gcc \
    g++ \
    git \
    gosu \
    gpg \
    make \
    xz-utils

RUN git clone --depth=1 --progress --verbose \
    https://github.com/raspberrypi/tools.git \ 
    pitools

ENV PATH=/pitools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin:/dlang/${COMPILER}-${COMPILER_VERSION}/bin:${PATH} \
    LD_LIBRARY_PATH=/dlang/${COMPILER}-${COMPILER_VERSION}/lib \
    LIBRARY_PATH=/dlang/${COMPILER}-${COMPILER_VERSION}/lib \ 
    CC=arm-linux-gnueabihf-gcc \
    LD=arm-linux-gnueabihf-ld \
    AR=arm-linux-gnueabihf-ar \
    PS1="(${COMPILER}-${COMPILER_VERSION}) \\u@\\h:\\w\$"

RUN curl -fsS -o /tmp/install.sh https://dlang.org/install.sh && \
    bash /tmp/install.sh -p /dlang install "${COMPILER}-${COMPILER_VERSION}" && \
    rm /tmp/install.sh && \
    rm -rf /dlang/${COMPILER}-*/lib32

RUN echo 'ldc2 -mtriple=armv6-linux-gnueabihf -gcc=arm-linux-gnueabihf-gcc "$@"' > /dlang/${COMPILER}-${COMPILER_VERSION}/bin/ldc-arm && \
    chmod +x /dlang/${COMPILER}-${COMPILER_VERSION}/bin/ldc-arm

RUN cd /tmp \
    rm -R "/dlang/${COMPILER}-${COMPILER_VERSION}/lib" && \
    "/dlang/${COMPILER}-${COMPILER_VERSION}/bin/ldc-build-runtime" --dFlags="-w;-mtriple=armv6-linux-gnueabihf" --cFlags="-fPIC" --targetSystem="Linux;UNIX" && \
    mkdir -p "/dlang/${COMPILER}-${COMPILER_VERSION}/lib" && \
    cp ldc-build-runtime.tmp/lib/*.a "/dlang/${COMPILER}-${COMPILER_VERSION}/lib" && \
    cp ldc-build-runtime.tmp/lib/*.so "/dlang/${COMPILER}-${COMPILER_VERSION}/lib" && \
    rm -R ldc-build-runtime.tmp

RUN apt-get autoremove -y gpg && \
    apt-get remove -y cmake cmake-data && \
    rm -rf /var/cache/apt

RUN cd /tmp \
    echo 'void main() {import std.stdio; stdout.writeln("it works");}' > test.d && \
    ldc-arm test.d && \
    readelf -h /tmp/test| grep 'Machine:' | sed 's/:/\n/g' | tail -n 1 | grep ARM > /dev/null && \
    rm test*

WORKDIR /src

RUN gosu nobody true && \
    rm -rf /var/lib/apt/lists/* && \
    chmod 755 -R /dlang

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ldc-arm", "--version"]
