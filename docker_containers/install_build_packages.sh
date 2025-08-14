#!/bin/bash

# Install system packages required for building InvenTree python libraries.
#Thesee were ported from the Alpine Linux packages.

apt-get update && apt-get install -y \
    gcc \
    g++ \
    musl-dev \
    libffi-dev \
    cargo \
    python3-dev \
    poppler-utils \
    libpango-1.0-0 \
    libpangoft2-1.0-0\
    libwebp-dev \
    sqlite3 \
    mariadb-client \
    libssl-dev \
    build-essential \
    libldap2-dev \
    linux-headers-generic \
    libgrpc++-dev \
    libjpeg-dev \
    libopenjp2-7-dev \
    libsqlite3-dev \
    zlib1g-dev \
    libmariadb-dev \
    libmariadb-dev-compat \
    libpq-dev \
    libpq5 \
    $@
    