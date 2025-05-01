# Hyperliquid Node Docker

This repository provides Docker Compose configurations for running a Hyperliquid node.

It's designed to work with [central-proxy-docker](https://github.com/CryptoManufaktur-io/central-proxy-docker) for Traefik and Prometheus remote write. If you need external network connectivity and Traefik integration, include `:ext-network.yml` in your `COMPOSE_FILE` setting within your `.env` file.

## Quick Setup

1.  **Prepare your environment:**
    Copy the default environment file and customize your settings:
    ```bash
    cp default.env .env
    nano .env
    ```
    Review and update values such as:
    *   `CHAIN`: Set to "Mainnet" or "Testnet".
    *   `MONIKER`: Choose a name for your node.
    *   `HL_NODE_VERSION`: Pin to a specific version if needed (default: `latest`).
    *   `EXPOSE_RPC`: Set to `true` if you need to access RPC/Gossip ports directly from your host machine.
    *   `COMPOSE_FILE`: Add other compose files like `:rpc-shared.yml` or `:ext-network.yml` as needed.
    *   Pruning settings (`PRUNE_SCHEDULE`, `PRUNE_RETAIN_DAYS`).
    *   Traefik settings (`DOMAIN`, `RPC_HOST`) if using `ext-network.yml`.

2.  **Expose ETH RPC Port (Optional):**
    The node's gossip ports (`GOSSIP_PORT_1`, `GOSSIP_PORT_2`) are always exposed on the host machine. If you also need the node's ETH RPC port (`ETH_RPC_PORT`) exposed directly on your host machine (e.g., for local tools or testing), set `EXPOSE_RPC=true` in your `.env` file **and** add `:rpc-shared.yml` to the `COMPOSE_FILE` list. For example:
    ```env
    # .env
    EXPOSE_RPC=true
    COMPOSE_FILE=hyperliquid.yml:rpc-shared.yml
    ```
    The specific ETH RPC port exposed is controlled by `ETH_RPC_PORT` in `.env`.

3.  **Install Docker & Services (if needed):**
    Run the install command (requires sudo):
    ```bash
    sudo ./hld install
    ```
    This command installs Docker CE and the systemd service if they aren't already present.

4.  **Start the Node:**
    Bring up your Hyperliquid node:
    ```bash
    ./hld up -d # Use -d to run in detached mode
    ```
    Or, if installed as a service:
    ```bash
    sudo systemctl start hyperliquid.service
    ```

5.  **Check Logs:**
    ```bash
    ./hld logs
    ```
    Or, if running as a service:
    ```bash
    sudo journalctl -u hyperliquid.service -f
    ```

6.  **Software Updates:**
    To update the node software and Docker images:
    ```bash
    ./hld update
    ./hld up -d --remove-orphans # Restart containers with updated images
    ```

## Node Setup

When you first start the node, the container will:
*   **Initialize the node** based on the `CHAIN` variable ("Mainnet" or "Testnet").
*   **Configure the appropriate peers** for the selected network.
*   **Download and verify the hl-visor binary** for the specified `HL_NODE_VERSION` using the official GPG key.

## Data Pruning

The setup includes an optional `pruner` service that automatically removes old blockchain data to manage disk space.
*   **Schedule:** Controlled by `PRUNE_SCHEDULE` in `.env` (uses cron format). Default is `0 3 * * *` (3 AM daily).
*   **Retention:** Controlled by `PRUNE_RETAIN_DAYS` in `.env`. Default is `7` days.
*   The pruner service runs by default. If you wish to disable it, you would need to manually remove or comment out the `pruner` service definition in `hyperliquid.yml`.

## Traefik Integration

If you include `:ext-network.yml` in your `COMPOSE_FILE` and configure `DOMAIN` and `RPC_HOST` in `.env`, the node service will be labeled for discovery by a Traefik instance running on the `DOCKER_EXT_NETWORK` (typically `traefik_default` from central-proxy-docker). This provides secure, proxied access (HTTPS) to the node's Ethereum RPC endpoint.

## Version

Hyperliquid Node Docker uses semantic versioning.

This is Hyperliquid Node Docker v1.1.0 (Updated based on these changes)