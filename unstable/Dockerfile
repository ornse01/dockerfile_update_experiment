FROM debian:unstable-slim@sha256:0023e01b19c586168e05c480ac7b2f7debedc8fc2dbf0d65fbecd4c674407d08
ARG SECURITY_UPDATE_DATE=2026-11-08

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
