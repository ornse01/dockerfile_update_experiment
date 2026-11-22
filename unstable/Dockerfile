FROM debian:unstable-slim@sha256:0616b6687a2b155010c25f9019d2e87461bed2b19b2733ca079b4700a2513949
ARG SECURITY_UPDATE_DATE=2026-11-22

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
