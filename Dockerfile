#
#
#

FROM arm32v6/alpine:3.8

LABEL maintainer="Nick Gregory <docker@openenterprise.co.uk>"

ARG LIBCEC_VERSION="4.0.2"
ARG LIBCEC_SHA256="b8b8dd31f3ebdd5472f03ab7d401600ea0d959b1288b9ca24bf457ef60e2ba27"

ARG P8PLATFORM_VERSION="2.1.0.1"
ARG P8PLATFORM_SHA256="064f8d2c358895c7e0bea9ae956f8d46f3f057772cb97f2743a11d478a0f68a0"

RUN apk add --no-cache --virtual .build-deps \
        build-base \
        git \
        curl \
        musl-dev \
        make \
        cmake \
        swig \
        python3-dev \
        libxrandr-dev \
        eudev-dev \
        raspberrypi-dev \
    && apk add --no-cache \
        eudev \
        python3 \
        libxrandr \
        raspberrypi-libs \
    && cd /tmp \
    && echo "==> p8 platform..." \
    && curl -fSL https://github.com/Pulse-Eight/platform/archive/p8-platform-${P8PLATFORM_VERSION}.tar.gz -o p8-platform-${P8PLATFORM_VERSION}.tar.gz \
    && echo "${P8PLATFORM_SHA256}  p8-platform-${P8PLATFORM_VERSION}.tar.gz" | sha256sum -c - \
    && tar xzf p8-platform-${P8PLATFORM_VERSION}.tar.gz \
    && mkdir /tmp/platform-p8-platform-${P8PLATFORM_VERSION}/build \
    && cd /tmp/platform-p8-platform-${P8PLATFORM_VERSION}/build \
    && cmake .. \
    && make \
    && make install \
    && cd /tmp \
    && echo "==> libcec..." \
    && curl -fSL https://github.com/Pulse-Eight/libcec/archive/libcec-${LIBCEC_VERSION}.tar.gz -o libcec-${LIBCEC_VERSION}.tar.gz \
    && echo "${LIBCEC_SHA256}  libcec-${LIBCEC_VERSION}.tar.gz" | sha256sum -c - \
    && tar xzf libcec-${LIBCEC_VERSION}.tar.gz \
    && ls -l /tmp \
    && mkdir /tmp/libcec-libcec-${LIBCEC_VERSION}/build \
    && cd /tmp/libcec-libcec-${LIBCEC_VERSION}/build \
    && cmake -D RPI_INCLUDE_DIR=/opt/vc/include -D RPI_LIB_DIR=/opt/vc/lib .. \
    && make \
    && make install \
    && cd /tmp \
    && echo "==> Installing cec-bride" \
    && mkdir /app \
    && git clone https://github.com/NixM0nk3y/cec-mqtt-bridge.git \
    && cd /tmp/cec-mqtt-bridge \
    && pip3 install -r requirements.txt \
    && cp bridge.py /app \
    && echo "==> Cleaning up ..." \
    && cd /tmp \
    && rm -rf \
        libcec-${LIBCEC_VERSION}.tar.gz libcec-${LIBCEC_VERSION} \
        p8-platform-${P8PLATFORM_VERSION}.tar.gz platform-p8-platform-${P8PLATFORM_VERSION} \
        cec-mqtt-bridge \
        /usr/local/include/p8-platform/ /usr/local/lib/libp8-platform.a /usr/local/lib/pkgconfig/p8-platform.pc /usr/local/lib/p8-platform/p8-platform-config.cmake \
        /usr/local/include/libcec 
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

COPY config.default.ini /app/config.ini

STOPSIGNAL SIGTERM

CMD ["python3","/app/bridge.py"]
