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
    *   `ENABLE_RPC`: Set to `false` to disable the `--serve-eth-rpc` flag (default: `true`).
    *   `EXPOSE_RPC`: Set to `true` if you need to access the ETH RPC port directly from your host machine.
    *   `COMPOSE_FILE`: Add other compose files like `:rpc-shared.yml` or `:ext-network.yml` as needed.
    *   Pruning settings (`PRUNE_SCHEDULE`, `PRUNE_RETAIN_DAYS`).
    *   Traefik settings (`DOMAIN`, `RPC_HOST`) if using `ext-network.yml`.

2.  **Expose ETH RPC Port (Optional):**
    The node's gossip ports (`GOSSIP_PORT_1`, `GOSSIP_PORT_2`) are always exposed on the host machine by default via `hyperliquid.yml`. If you also need the node's ETH RPC port (`ETH_RPC_PORT`) exposed directly on your host machine (e.g., for local tools or testing), set `EXPOSE_RPC=true` in your `.env` file **and** add `:rpc-shared.yml` to the `COMPOSE_FILE` list. For example:
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
    This command installs Docker CE and the systemd service if they aren't already present. After installation, both `hld` and `ethd` commands can be used interchangeably.
    *(Note: While this installs a systemd service, the following instructions focus on direct `docker compose` usage via the `hld`/`ethd` script).*

4.  **Start the Node:**
    Bring up your Hyperliquid node using the wrapper script:
    ```bash
    ./hld up -d # Or ./ethd up -d
    ```

5.  **Check Logs:**
    View the container logs using the wrapper script:
    ```bash
    ./hld logs # Or ./ethd logs
    ```

6.  **Software Updates:**
    To update the node software and Docker images:
    ```bash
    ./hld update # Or ./ethd update
    ./hld up -d --remove-orphans # Or ./ethd up -d --remove-orphans
    ```

## Node Setup

When you first start the node, the container will:
*   **Initialize the node** based on the `CHAIN` variable ("Mainnet" or "Testnet").
*   **Configure the appropriate peers** for the selected network.
*   **Download and verify the hl-visor binary** for the specified `HL_NODE_VERSION` using the official GPG key.
*   A basic **healthcheck** is configured to monitor the RPC endpoint (if enabled).

## Data Pruning

The setup includes an optional `pruner` service that automatically removes old blockchain data to manage disk space.
*   **Schedule:** Controlled by `PRUNE_SCHEDULE` in `.env` (uses cron format). Default is `0 3 * * *` (3 AM daily).
*   **Retention:** Controlled by `PRUNE_RETAIN_DAYS` in `.env`. Default is `7` days.
*   The pruner service runs by default. If you wish to disable it, you would need to manually remove or comment out the `pruner` service definition in `hyperliquid.yml`.

## Traefik Integration

If you include `:ext-network.yml` in your `COMPOSE_FILE` and configure `DOMAIN` and `RPC_HOST` in `.env`, the node service will be labeled for discovery by a Traefik instance running on the `DOCKER_EXT_NETWORK` (typically `traefik_default` from central-proxy-docker). This provides secure, proxied access (HTTPS) to the node's Ethereum RPC endpoint.

## Deployment Considerations

### AWS EC2
*   **Security Groups:** Ensure your EC2 instance's Security Group allows inbound traffic on the necessary ports:
    *   Gossip Ports (`GOSSIP_PORT_1`, `GOSSIP_PORT_2`, default 4001/tcp, 4002/tcp) from relevant peers (or `0.0.0.0/0` if unsure, but be cautious). These are always exposed by the container.
    *   ETH RPC Port (`ETH_RPC_PORT`, default 3001/tcp) *only if* `EXPOSE_RPC=true` and `rpc-shared.yml` is included, from your allowed IP addresses.
    *   SSH (22/tcp) from your management IP.
*   **Storage:** The `hl-data` Docker volume stores blockchain data. For data persistence across instance stops/restarts or failures, consider mapping this volume to a directory on an attached EBS volume. You can do this by changing the `hl-data` volume definition in `hyperliquid.yml` from a named volume to a bind mount:
    ```yaml
    volumes:
      # Example: Map to /mnt/ebs/hyperliquid-data on the host
      - /mnt/ebs/hyperliquid-data:/home/hluser/hl/data
    # Remove the named volume definition at the bottom
    # volumes:
    #  hl-data:
    ```
    Ensure the host directory (`/mnt/ebs/hyperliquid-data` in the example) exists and has appropriate permissions.
*   **Instance Size:** Choose an EC2 instance type with sufficient CPU, RAM, and network bandwidth. Monitor resource usage after deployment.

### Resource Limits
*   For stable operation, especially in resource-constrained environments like smaller EC2 instances, consider setting resource limits (CPU, memory) for the `node` container. Uncomment and adjust the `deploy.resources` section in `hyperliquid.yml` as needed based on observed usage and instance capacity.

## Version

Hyperliquid Node Docker uses semantic versioning.

This is Hyperliquid Node Docker v1.2.0