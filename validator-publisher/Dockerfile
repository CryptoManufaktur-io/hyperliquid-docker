FROM ubuntu:24.04

ARG USERNAME=hyperliquid
ARG VALIDATOR_PUBLISHER_VISOR_URL=https://binaries.hyperliquid.xyz/validator-publisher/visor

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl jq \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /usr/sbin/nologin "${USERNAME}" \
  && mkdir -p \
    /opt/validator-publisher/bin \
    /opt/validator-publisher/config \
    /opt/validator-publisher/logs \
    /opt/validator-publisher/state \
    /opt/validator-publisher/tmp \
  && chown -R "${USERNAME}:${USERNAME}" /opt/validator-publisher

RUN curl -fsSL "${VALIDATOR_PUBLISHER_VISOR_URL}" -o /opt/validator-publisher/bin/validator-publisher-visor \
  && chmod 0755 /opt/validator-publisher/bin/validator-publisher-visor \
  && chown "${USERNAME}:${USERNAME}" /opt/validator-publisher/bin/validator-publisher-visor

COPY validator-publisher/docker-entrypoint.sh /usr/local/bin/validator-publisher-entrypoint.sh
COPY scripts/render_validator_publisher_config.sh /usr/local/bin/render_validator_publisher_config.sh
RUN chmod 0755 \
    /usr/local/bin/validator-publisher-entrypoint.sh \
    /usr/local/bin/render_validator_publisher_config.sh

WORKDIR /opt/validator-publisher
USER ${USERNAME}

ENTRYPOINT ["/usr/local/bin/validator-publisher-entrypoint.sh"]
