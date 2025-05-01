FROM ubuntu:24.04
ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID
ARG CHAIN=Mainnet  # Default to Mainnet
# Add ARGs for configurable values
ARG PUB_KEY_URL=https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc
ARG MAINNET_ROOT_IPS='[{"Ip": "35.213.122.164"}, {"Ip": "35.213.89.139"}]'

# Create user and install dependencies
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install -y curl gnupg net-tools \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl
USER $USERNAME
WORKDIR /home/$USERNAME
# Set visor config and gossip config based on CHAIN using build args
RUN if [ "$CHAIN" = "Mainnet" ]; then \
        echo "{\"chain\": \"Mainnet\"}" > /home/$USERNAME/visor.json && \
        echo "{ \"root_node_ips\": ${MAINNET_ROOT_IPS}, \"try_new_peers\": true, \"chain\": \"Mainnet\" }" > /home/$USERNAME/override_gossip_config.json ; \
    elif [ "$CHAIN" = "Testnet" ]; then \
        echo "{\"chain\": \"Testnet\"}" > /home/$USERNAME/visor.json ; \
        # Note: No override_gossip_config.json created for Testnet by default.
    else \
        echo "ERROR: Invalid CHAIN specified: $CHAIN. Only 'Mainnet' and 'Testnet' are supported." >&2 && exit 1 ; \
    fi
# Remove ENV for PUB_KEY_URL as it's now an ARG
# ENV PUB_KEY_URL=https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc
# Import GPG public key using ARG
RUN curl -o /home/$USERNAME/pub_key.asc ${PUB_KEY_URL} \
    && gpg --import /home/$USERNAME/pub_key.asc
# Download and verify hl-visor binary
RUN if [ "$CHAIN" = "Mainnet" ]; then \
        curl -o /home/$USERNAME/hl-visor https://binaries.hyperliquid.xyz/Mainnet/hl-visor && \
        curl -o /home/$USERNAME/hl-visor.asc https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc ; \
    elif [ "$CHAIN" = "Testnet" ]; then \
        curl -o /home/$USERNAME/hl-visor https://binaries.hyperliquid.xyz-testnet/Testnet/hl-visor && \
        curl -o /home/$USERNAME/hl-visor.asc https://binaries.hyperliquid.xyz-testnet/Testnet/hl-visor.asc ; \
    else \
        echo "ERROR: Invalid CHAIN specified during binary download. Only 'Mainnet' and 'Testnet' are supported." >&2 && exit 1 ; \
    fi \
    && gpg --verify /home/$USERNAME/hl-visor.asc /home/$USERNAME/hl-visor \
    && chmod +x /home/$USERNAME/hl-visor
# Remove entrypoint.sh creation as it's overridden in docker-compose.yml
# RUN echo '#!/bin/bash' > /home/$USERNAME/entrypoint.sh && \
#     echo 'ARGS=("/home/hluser/hl-visor" "run-non-validator" "--replica-cmds-style" "recent-actions" "--serve-eth-rpc")' >> /home/$USERNAME/entrypoint.sh && \
#     echo 'exec "${ARGS[@]}"' >> /home/$USERNAME/entrypoint.sh && \
#     chmod +x /home/$USERNAME/entrypoint.sh

# Expose default internal ports (informational)
EXPOSE 4001 4002 3001