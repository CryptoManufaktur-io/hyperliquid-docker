FROM ubuntu:24.04
ARG USERNAME
ARG USER_UID=10001
ARG CHAIN
ARG PUB_KEY_URL

# Create user and install dependencies
RUN groupadd --gid $USER_UID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_UID -m $USERNAME \
    && apt-get update -y && apt-get install -y curl gnupg net-tools jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data /home/$USERNAME/hl/hyperliquid_data \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

COPY docker-entrypoint.sh /usr/bin/docker-entrypoint.sh
RUN chmod +x /usr/bin/docker-entrypoint.sh

USER $USERNAME
WORKDIR /home/$USERNAME

# Import GPG public key using ARG
RUN curl -sSL -o /home/$USERNAME/pub_key.asc ${PUB_KEY_URL} \
    && gpg --import /home/$USERNAME/pub_key.asc


RUN if [ "$CHAIN" = "Testnet" ]; then \
      PREFIX="https://binaries.hyperliquid-testnet.xyz/Testnet"; \
      echo '{"chain": "Testnet"}' > /home/$USERNAME/visor.json; \
    else \
      PREFIX="https://binaries.hyperliquid.xyz/Mainnet"; \
      echo '{"chain": "Mainnet"}' > /home/$USERNAME/visor.json; \
    fi \
 && curl -fsSL -o hl-visor    "${PREFIX}/hl-visor" \
 && curl -fsSL -o hl-visor.asc "${PREFIX}/hl-visor.asc" \
 && gpg --verify hl-visor.asc hl-visor \
 && chmod +x hl-visor

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
# ENTRYPOINT ["bash"]