FROM debian:stable-slim@sha256:0d97731c59efdde181e19c4a5ec22d16e9eefcb73175598b9b7bae712c7214eb
ARG SECURITY_UPDATE_DATE=2026-08-01

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
