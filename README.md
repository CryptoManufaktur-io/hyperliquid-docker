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

## Tools and Utilities

This setup includes several utility tools for interacting with your Hyperliquid node and the network.

### CLI Tool

The CLI tool provides access to the Hyperliquid command-line interface within the same environment as your consensus node:

**Interactive mode:**
```bash
docker compose --profile tools run --rm cli
```

**Command mode:**
```bash
docker compose --profile tools run --rm cli hl-visor --help
```

The CLI tool shares the same data volume as the consensus node, giving it access to all node files and configurations.

### Validator Information Query

Query validator summaries and statistics from the Hyperliquid API:

**Basic usage:**
```bash
# Query all validators (defaults to Testnet)
docker compose --profile tools run --rm validator-info

# Query Mainnet validators
CHAIN=Mainnet docker compose --profile tools run --rm validator-info

# Query Testnet validators explicitly
CHAIN=Testnet docker compose --profile tools run --rm validator-info
```

**Filter specific validators using jq:**
```bash
# Find a specific validator by name
docker compose --profile tools run --rm validator-info | jq '.[] | select(.name == "ValiDAO")'

# Show only active validators
docker compose --profile tools run --rm validator-info | jq '.[] | select(.isActive == true)'

# Show validators with 0% commission
docker compose --profile tools run --rm validator-info | jq '.[] | select(.commission == "0.0")'

# Show jailed validators
docker compose --profile tools run --rm validator-info | jq '.[] | select(.isJailed == true)'

# Sort validators by stake (highest first)
docker compose --profile tools run --rm validator-info | jq 'sort_by(-.stake | tonumber)'
```

**Suppress informational messages:**
```bash
# Clean JSON output only
docker compose --profile tools run --rm validator-info 2>/dev/null | jq '.'
```

## Node Setup

When you first start the node, the container will:
*   **Initialize the node** based on the `CHAIN` variable ("Mainnet" or "Testnet").
*   **Configure the appropriate peers** based on `MAINNET_ROOT_IPS` for Mainnet or `TESTNET_ROOT_IPS` for Testnet.
*   **Download and verify the hl-visor binary** using the official GPG key from `PUB_KEY_URL`.
*   If `NODE_TYPE` is set to "validator", a node configuration file will be created with the provided private key. You can generate a private key using `openssl rand -hex 32` if needed. The system will automatically display the corresponding public address during startup.

### Firewall Configuration for Validators

For mainnet validators, proper firewall configuration is essential for DDOS protection and secure peer connectivity. The container automatically creates a `firewall_ips.json` file based on the `FIREWALL_IPS` environment variable.

**Configuration:**
1. **Set the FIREWALL_IPS variable** in your `.env` file with a JSON array of validator IPs:
   ```env
   FIREWALL_IPS='[{"ip": "1.2.3.4", "name": "Hyper Foundation 1", "allowed": true}, {"ip": "1.2.3.4", "name": "Hyper Foundation 2", "allowed": true}]'
   ```

2. **Required format:** Each entry must include:
   - `ip`: The IPv4 address of the validator
   - `name`: A descriptive name for the validator
   - `allowed`: Boolean flag (typically `true` for whitelisted IPs)

3. **File creation:** The container automatically creates `~/hl/file_mod_time_tracker/firewall_ips.json` with the proper format:
   ```json
   [
     ["1.2.3.4", {"name": "Hyper Foundation 1", "allowed": true}],
     ["1.2.3.4", {"name": "Hyper Foundation 2", "allowed": true}]
   ]
   ```

**Important notes:**
- The firewall configuration is created automatically when `NODE_TYPE=validator` or when `FIREWALL_IPS` is explicitly set
- An empty array `[]` creates an empty firewall configuration
- The default for unknown validators is to deny connections, so keep this file up-to-date
- This configuration works in conjunction with your actual firewall rules for ports 4001-4004

**Validator IP management:**
When changing validator IP addresses, ensure you:
1. Run connectivity checks using `hl-node --chain <chain> check-reachability`
2. Update the `FIREWALL_IPS` configuration and restart the container

### Dynamic Configuration Updates

You can update node configuration (gossip peers and firewall settings) without restarting the consensus container.

**Usage:**
1. Edit your `.env` file with new settings
2. Run: `docker compose run --rm config-sync`

This will apply your `.env` changes to the running node immediately. Useful for updating firewall IPs, switching networks, or changing peer configurations.

### UFW Firewall Rules

In addition to the application-level firewall configuration above, you should also configure UFW (Uncomplicated Firewall) on your host system to allow connections from trusted validator IPs. Here are example commands for allowing connections from known validators:

```bash
# XXX Company
sudo ufw allow from 1.2.3.4 to any port 4000:4010 proto tcp comment "XXX - TCP"
sudo ufw allow from 1.2.3.4 to any port 4000:4010 proto udp comment "XXX - UDP"
```

**UFW Configuration Notes:**
- Replace the IP addresses with the current validator IPs from your `FIREWALL_IPS` configuration
- The port range `4000:4010` should match your `P2P_PORT_RANGE` setting
- Include both TCP and UDP protocols for each validator
- Use descriptive comments to identify each validator for easier management
- To view current UFW rules: `sudo ufw status numbered`
- To delete a rule: `sudo ufw delete [rule_number]`

### Accessing Your Node

**Direct container access:**
```bash
# Access the running consensus container
docker compose exec consensus bash

# View real-time logs
./hld logs -f

# Check node status
docker compose exec consensus hl-visor --help
```

## Validator Voting

For validators participating in governance, you can vote on L1 actions directly from your node.

### How to Vote

Voting involves sending a signed action with your validator wallet:

```bash
# Vote "yes" on an action (replace PERPNAME with the actual perpetual name)
docker compose exec consensus hl-node --chain Mainnet --key <validator-key> send-signed-action '{"type": "validatorL1Vote", "D": "PERPNAME"}'
```

### Important Notes

- **Use validator wallet**: Send votes with your validator (cold) wallet, not the signer address
- **Chain specification**: Always specify `--chain Mainnet` or `--chain Testnet`
- **Key parameter**: Replace `<validator-key>` with your actual validator private key
- **Voting behavior**: Sending any action votes "yes" - there's currently no way to vote "no"
- **Vote expiration**: Votes expire in 1 day if quorum is not met
- **Concurrency limit**: Validators can only vote on 50 concurrent actions
- **No unvoting**: There's currently no way to unvote once submitted

### Check Vote Status

You can view current vote summaries using the API:

```bash
# Get current validator L1 votes
curl -X POST --header "Content-Type: application/json" \
  --data '{"type":"validatorL1Votes"}' \
  https://api.hyperliquid.xyz/info
```

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

*   **Hardware Requirements:** The node requires adequate CPU, RAM, and disk space. Recommended minimum is 4 CPU cores, 8GB RAM, and 500GB SSD storage.
*   **Network Configuration:** Ensure that the P2P ports specified in `P2P_PORT_RANGE` are accessible from the internet for proper peer connections.
*   **Data Volume:** The blockchain data will grow over time. Monitor disk usage regularly. The pruner service will help manage disk usage automatically.
*   **Security:** If running a validator node, ensure your private key is stored securely and not exposed in environment variables or logs.
*   **Backups:** Regularly back up your `.env` file and any custom configurations.
*   **Service Profiles:** Use Docker Compose profiles to run different components:
    - Default: `consensus` and `pruner` services
    - Tools: `--profile tools` for CLI and validator-info utilities
    - Monitoring: Include `:monitoring.yml` in `COMPOSE_FILE` for metrics collection

## Troubleshooting

**Common issues and solutions:**

*   **Port conflicts:** Ensure P2P and RPC ports are not in use by other services
*   **Sync issues:** Check network connectivity and peer configuration
*   **Disk space:** Monitor storage usage and verify pruner is running
*   **Permission errors:** Verify file ownership matches the configured `USERNAME`

**Useful commands:**
```bash
# Check service status
docker compose ps

# View resource usage
docker compose top

# Restart specific service
docker compose restart consensus

# View detailed logs with timestamps
./hld logs --timestamps consensus
```

## Version

Hyperliquid Node Docker uses semantic versioning.

This is Hyperliquid Node Docker v1.3.0