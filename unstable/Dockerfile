FROM debian:unstable-slim@sha256:f356315819992f4aa30e377208b8b37983d4c3420efa7d490ce4e93a213fd66a
ARG SECURITY_UPDATE_DATE=2026-08-30

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
