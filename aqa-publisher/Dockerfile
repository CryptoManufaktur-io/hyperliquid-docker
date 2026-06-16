FROM rust:1.91-slim AS builder

ARG AQA_PUBLISHER_VERSION=v1.2.0

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    libssl-dev \
    pkg-config \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone --depth 1 --branch "${AQA_PUBLISHER_VERSION}" https://github.com/native-markets/aqa-publisher.git .

RUN cargo build --release --locked \
    --bin publish_daemon \
    --bin publish_once \
    --bin print_current

FROM debian:bookworm-slim

ARG USERNAME=hyperliquid

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /usr/sbin/nologin "${USERNAME}"

COPY --from=builder /build/target/release/publish_daemon /usr/local/bin/publish_daemon
COPY --from=builder /build/target/release/publish_once /usr/local/bin/publish_once
COPY --from=builder /build/target/release/print_current /usr/local/bin/print_current
COPY aqa-publisher/docker-entrypoint.sh /usr/local/bin/aqa-publisher-entrypoint.sh

RUN chmod 0755 \
    /usr/local/bin/publish_daemon \
    /usr/local/bin/publish_once \
    /usr/local/bin/print_current \
    /usr/local/bin/aqa-publisher-entrypoint.sh

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ENTRYPOINT ["/usr/local/bin/aqa-publisher-entrypoint.sh"]
