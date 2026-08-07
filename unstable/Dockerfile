FROM debian:unstable-slim@sha256:26bc122d974bb7f2d1a61ac4ac595584d7f03d048bc2c284debcebc012d91a31
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
