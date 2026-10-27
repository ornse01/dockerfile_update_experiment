FROM debian:unstable-slim@sha256:acd2c764ef5fbe908e13a0f3fca9efebee362ecd40419b6eca35b234b09f62d8
ARG SECURITY_UPDATE_DATE=2026-10-24

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    wget \
    vim \
    procps \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*

CMD ["bash"]
