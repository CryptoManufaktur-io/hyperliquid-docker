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
    *   `USERNAME`: Username for the node container (default: `hyperliquid`).
    *   `NODE_TYPE`: Set to "non-validator" or "validator".
    *   `ENABLE_EVM_RPC`: Set to `true` to enable the `--serve-eth-rpc` flag (default: `true`).
    *   `P2P_PORT_RANGE`: Port range for P2P communication (default: `4000-4010`).
    *   `EVM_RPC_PORT`: Port for ETH RPC access (default: `3001`).
    *   `COMPOSE_FILE`: Add other compose files like `:rpc-shared.yml` or `:ext-network.yml` as needed.
    *   `MAINNET_ROOT_IPS`: JSON array of seed peer IPs for Mainnet.
    *   `TESTNET_ROOT_IPS`: JSON array of seed peer IPs for Testnet.
    *   `EXTRA_FLAGS`: Additional command-line flags for hl-visor.

2.  **Expose EVM RPC Port (Optional):**
    The node's P2P ports are always exposed on the host machine by default via `hyperliquid.yml`. If you also need the node's EVM RPC port exposed directly on your host machine, include `:rpc-shared.yml` in the `COMPOSE_FILE` list:
    ```env
    # .env
    COMPOSE_FILE=hyperliquid.yml:rpc-shared.yml
    ```
    The EVM RPC port exposed is controlled by `EVM_RPC_PORT` in `.env`.

3.  **Install Docker & Services (if needed):**
    Run the install command (requires sudo):
    ```bash
    sudo ./hld install
    ```
    This command installs Docker CE and the systemd service if they aren't already present.

4.  **Start the Node:**
    Bring up your Hyperliquid node using the wrapper script:
    ```bash
    ./hld up -d
    ```

5.  **Check Logs:**
    View the container logs using the wrapper script:
    ```bash
    ./hld logs
    ```

6.  **Software Updates:**
    To update the node software and Docker images:
    ```bash
    ./hld update
    ./hld up -d --remove-orphans
    ```

## Node Setup

When you first start the node, the container will:
*   **Initialize the node** based on the `CHAIN` variable ("Mainnet" or "Testnet").
*   **Configure the appropriate peers** based on `MAINNET_ROOT_IPS` for Mainnet or `TESTNET_ROOT_IPS` for Testnet.
*   **Download and verify the hl-visor binary** using the official GPG key from `PUB_KEY_URL`.
*   If `NODE_TYPE` is set to "validator", a node configuration file will be created with the provided private key. You can generate a private key using `openssl rand -hex 32` if needed. The system will automatically display the corresponding public address during startup.

## Data Pruning

The setup includes a `pruner` service that automatically removes old blockchain data to manage disk space.
*   **Schedule:** Controlled by the cron job in the pruner container, which runs at 3 AM daily (`0 3 * * *`).
*   **Implementation:** Uses the official Hyperliquid pruning script to safely remove historical data while maintaining node functionality.

## Monitoring

The setup includes a monitoring service that collects and exposes metrics for your Hyperliquid node. This helps you track the health and performance of your node.

### Enabling Monitoring

1. **Include the monitoring compose file:**
   Ensure that `:monitoring.yml` is included in your `COMPOSE_FILE` setting in the `.env` file:
   ```env
   COMPOSE_FILE=hyperliquid.yml:monitoring.yml
   ```

2. **Configure monitoring settings:**
   In your `.env` file, set the following parameters:
   ```env
   NODE_ALIAS=your-node-name     # A descriptive name for your node
   MONITORING_PORT=8086          # The port on which metrics will be exposed
   LOG_LEVEL=info                # Log level for the monitoring service
   ```

3. **Start the monitoring service:**
   When you run `./hld up -d`, the monitoring service will start automatically.

### Accessing Metrics

The monitoring service exposes Prometheus metrics on port 8086 (or your configured `MONITORING_PORT`). You can access these metrics at:
```
http://your-server-ip:8086/metrics
```

### Visualizing Metrics with Grafana

To visualize the metrics collected:

1. **Set up Prometheus:**
   Configure Prometheus to scrape metrics from your node's monitoring endpoint.

2. **Import the dashboard:**
   - Download the pre-configured Grafana dashboard from [hyperliquid-exporter/grafana/grafana.json](https://github.com/validaoxyz/hyperliquid-exporter/blob/main/grafana/grafana.json)
   - In Grafana, go to Dashboard → Import and upload the JSON file
   - Select your Prometheus data source

### Available Metrics

The monitoring service collects various metrics, including:

* **Block metrics:** Height, time, lag, proposer statistics
* **Node status:** Software version, sync status
* **Validator metrics:** Status, jailing information, stake distribution
* **EVM metrics:** Transaction throughput and performance

### Integration with Existing Monitoring Stack

If you're using [central-proxy-docker](https://github.com/CryptoManufaktur-io/central-proxy-docker), the monitoring service is automatically configured for discovery through the `metrics.*` labels.

### External Monitoring Services

A sample public dashboard is available at [ValiDAO Hyperliquid Testnet Monitor](https://hyperliquid-testnet-monitor.validao.xyz/public-dashboards/ff0fbe53299b4f95bb6e9651826b26e0).

## Traefik Integration

If you include `:ext-network.yml` in your `COMPOSE_FILE` and configure `DOMAIN`, `RPC_HOST`, and `RPC_LB` in `.env`, the consensus service will be labeled for discovery by a Traefik instance running on the `DOCKER_EXT_NETWORK`. This provides secure, proxied access (HTTPS) to the node's EVM RPC endpoint.

## Deployment Considerations

When deploying your Hyperliquid node, consider the following:

*   **Hardware Requirements:** The node requires adequate CPU, RAM, and disk space. Recommended minimum is 4 CPU cores, 8GB RAM, and 500GB SSD.
*   **Network Configuration:** Ensure that the P2P ports specified in `P2P_PORT_RANGE` are accessible from the internet for proper peer connections.
*   **Data Volume:** The blockchain data will grow over time. Monitor disk usage regularly. Pruner will reduce the node disk usage.
*   **Security:** If running a validator node, ensure your private key is stored securely and not exposed in environment variables or logs.
*   **Backups:** Regularly back up your `.env` file and any custom configurations.

## Version

Hyperliquid Node Docker uses semantic versioning.

This is Hyperliquid Node Docker v1.3.0