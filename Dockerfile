FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    gettext-base \
    unzip \
    curl \
    iputils-ping \
    libaio1t64 \
    libx11-6 \
    libxext6 \
    libxrender1 \
    libxt6 \
    libfontconfig1 \
    libfreetype6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m fluig && \
    mkdir -p /opt/totvs/fluig /installer/scripts

WORKDIR /opt/totvs/fluig

COPY scripts/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8080 8443 8983 8888 7070

ENTRYPOINT ["/entrypoint.sh"]
