# syntax=docker/dockerfile:1.7

ARG UBUNTU_IMAGE=ubuntu:resolute

FROM ${UBUNTU_IMAGE} AS package

ARG HHVM_REPO=https://github.com/hershel-theodore-layton/hhvm.git
ARG HHVM_REF=hhvm-oss-20260605
ARG IS_NIGHTLY=
ARG JOBS=
ARG DISTRO=ubuntu-26.04-resolute
ARG LLVM_VERSION=20
ARG HHVM_BUILD_FLAG=--ubuntu-26.04

ENV DEBIAN_FRONTEND=noninteractive \
    HHVM_DISABLE_NUMA=true \
    HHVM_DISABLE_PERSONALITY=true \
    OUT=/var/out \
    DISTRO=${DISTRO} \
    LLVM_VERSION=${LLVM_VERSION} \
    IS_NIGHTLY=${IS_NIGHTLY}

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends ca-certificates git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

ARG HHVM_REVISION
RUN git clone --filter=blob:none --single-branch --branch "${HHVM_REF}" "${HHVM_REPO}" hhvm && \
    test "$(git -C hhvm rev-parse HEAD)" = "${HHVM_REVISION}"

WORKDIR /usr/src/hhvm

RUN <<'EOF'
set -e

HHVM_VERSION="$(awk '
  /^# define HHVM_VERSION_MAJOR / { major = $4 }
  /^# define HHVM_VERSION_MINOR / { minor = $4 }
  /^# define HHVM_VERSION_PATCH / { patch = $4 }
  END { if (!major || !minor || !patch) exit 1; printf "%02d.%02d.%02d\n", major, minor, patch }
' hphp/runtime/version.h)"
export HHVM_VERSION

if [ -n "${JOBS}" ]; then
  export JOBS
fi

if [ -n "${HHVM_BUILD_FLAG}" ]; then
  ./build.sh "${HHVM_BUILD_FLAG}"
else
  ./build.sh
fi
EOF

RUN mkdir -p /artifacts && \
    deb="$(find /var/out -maxdepth 1 -type f \( -name 'hhvm_*.deb' -o -name 'hhvm-nightly_*.deb' \) ! -name '*-dbgsym*' ! -name '*-dev_*' -printf '%T@ %p\n' | sort -nr | awk 'NR == 1 { print $2 }')" && \
    test -n "${deb}" && \
    cp "${deb}" /artifacts/hhvm.deb && \
    cp /var/out/* /artifacts/

FROM scratch AS artifacts
COPY --from=package /artifacts/ /

FROM ${UBUNTU_IMAGE} AS basic

ENV DEBIAN_FRONTEND=noninteractive \
    HHVM_DISABLE_PERSONALITY=true \
    HHVM_DISABLE_NUMA=true

RUN --mount=type=bind,from=package,source=/artifacts/hhvm.deb,target=/tmp/hhvm.deb \
    apt-get update -y && \
    apt-get install -y /tmp/hhvm.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM basic AS full

ARG WATCHMAN_VERSION=v2025.05.26.00
ARG WATCHMAN_URL=https://github.com/facebook/watchman/releases/download/v2025.05.26.00/watchman-v2025.05.26.00-linux.zip

COPY --from=package /artifacts/hhvm.deb /var/tmp/hhvm-installer/hhvm.deb

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends git php-cli php-curl php-zip curl wget unzip liblzma5 && \
    wget https://raw.githubusercontent.com/composer/getcomposer.org/refs/heads/main/web/installer -O - -q | php -- --quiet && \
    mv composer.phar /usr/local/bin/composer && \
    mkdir -p /var/tmp/hhvm-installer && \
    cd /var/tmp/hhvm-installer && \
    wget "${WATCHMAN_URL}" -O watchman.zip && \
    unzip watchman.zip && \
    cd "watchman-${WATCHMAN_VERSION}-linux" && \
    mkdir -p /usr/local/bin /usr/local/lib /usr/local/var/run/watchman && \
    cp bin/* /usr/local/bin && \
    cp lib/* /usr/local/lib && \
    chmod 755 /usr/local/bin/watchman && \
    chmod 2777 /usr/local/var/run/watchman && \
    rm -f /usr/local/lib/liblzma.so.5 && \
    ln -s /usr/lib/x86_64-linux-gnu/liblzma.so.5 /usr/local/lib/liblzma.so.5 && \
    echo "hhvm.autoload.enabled=true" >> /etc/hhvm/php.ini && \
    echo "hhvm.autoload.enabled=true" >> /etc/hhvm/server.ini && \
    echo "hhvm.autoload.db.path=/var/tmp/hhvm-autoload-%{euid}-%{schema}.db" >> /etc/hhvm/php.ini && \
    echo "hhvm.autoload.db.path=/var/tmp/hhvm-autoload-%{euid}-%{schema}.db" >> /etc/hhvm/server.ini && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/hhvm-installer
