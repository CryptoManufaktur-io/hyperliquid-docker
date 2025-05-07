FROM ubuntu:24.04
ARG USERNAME=hluser
ARG USER_UID=10000
ARG USER_GID=$USER_UID

# Add ARGs for configurable values (IPs and peer settings will be passed as ENV vars to container at runtime)
ARG PUB_KEY_URL=https://raw.githubusercontent.com/hyperliquid-dex/node/refs/heads/main/pub_key.asc

# Create user and install dependencies
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update -y && apt-get install -y curl gnupg net-tools jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/$USERNAME/hl/data /home/$USERNAME/hl/hyperliquid_data \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/hl

USER $USERNAME
WORKDIR /home/$USERNAME

# visor.json and override_gossip_config.json will be created by the entrypoint script at runtime
# Remove RUN commands that created these files based on ARG CHAIN

# Import GPG public key using ARG
RUN curl -sSL -o /home/$USERNAME/pub_key.asc ${PUB_KEY_URL} \
    && gpg --import /home/$USERNAME/pub_key.asc

# Download and verify Mainnet hl-visor binary
RUN curl -sSL -o /home/$USERNAME/hl-visor-mainnet https://binaries.hyperliquid.xyz/Mainnet/hl-visor && \
    curl -sSL -o /home/$USERNAME/hl-visor-mainnet.asc https://binaries.hyperliquid.xyz/Mainnet/hl-visor.asc && \
    gpg --verify /home/$USERNAME/hl-visor-mainnet.asc /home/$USERNAME/hl-visor-mainnet && \
    chmod +x /home/$USERNAME/hl-visor-mainnet

# Download and verify Testnet hl-visor binary
RUN curl -sSL -o /home/$USERNAME/hl-visor-testnet https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor && \
    curl -sSL -o /home/$USERNAME/hl-visor-testnet.asc https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor.asc && \
    gpg --verify /home/$USERNAME/hl-visor-testnet.asc /home/$USERNAME/hl-visor-testnet && \
    chmod +x /home/$USERNAME/hl-visor-testnet

# Download and verify hl-node binary
RUN curl -sSL -o /home/$USERNAME/hl-node https://binaries.hyperliquid.xyz/$CHAIN/hl-node && \
    chmod +x /home/$USERNAME/hl-node

# Expose default internal ports (informational)
EXPOSE 4001 4002 3001