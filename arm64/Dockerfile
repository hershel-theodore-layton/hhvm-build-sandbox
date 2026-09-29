# syntax=docker/dockerfile:1
FROM ubuntu:26.04 AS basic
ENV DEBIAN_FRONTEND=noninteractive HHVM_DISABLE_PERSONALITY=true HHVM_DISABLE_NUMA=true
RUN --mount=type=bind,source=out/arm64,target=/packages \
    apt-get update && apt-get install -y /packages/hhvm_*_arm64.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
CMD ["hhvm", "--version"]

FROM basic AS full
RUN apt-get update && \
    apt-get install -y --no-install-recommends git php-cli php-curl php-zip composer curl wget unzip watchman && \
    printf '\nhhvm.autoload.enabled=true\nhhvm.autoload.db.path=/var/tmp/hhvm-autoload-%%{euid}-%%{schema}.db\n' >> /etc/hhvm/php.ini && \
    printf '\nhhvm.autoload.enabled=true\nhhvm.autoload.db.path=/var/tmp/hhvm-autoload-%%{euid}-%%{schema}.db\n' >> /etc/hhvm/server.ini && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
