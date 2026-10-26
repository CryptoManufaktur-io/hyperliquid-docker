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
    *   `VISOR_AUTO_UPDATE`: Refresh `hl-visor` on container start when the published build differs (default: `true`).

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

## Validator Publisher

This repository also includes an optional `validator-publisher` compose file for a dedicated publisher host. Do not include it on the validator or sentry hosts. The publisher supports Hyperliquid bridge voting, reference oracle publishing, and outcome action review alerts.

The upstream publisher README is here:
https://binaries.hyperliquid.xyz/validator-publisher/README.md

### Runtime Requirements

For Mainnet, prepare the following values outside git:

- A validator publisher agent private key approved by the validator.
- Seven Arbitrum mainnet RPC endpoints named `alchemy`, `quicknode`, `infura`, `chainstack`, `ankr`, `drpc`, and one operator-selected provider such as `getblock`.
- At least one RPC provider opted into near-tip `eth_getLogs` deposit discovery via `VALIDATOR_PUBLISHER_RPC_LOG_DISCOVERY`. Hyperliquid requires this as of the week of 2026-07-27. Only enable it on providers whose plan supports `eth_getLogs` with topic filters over a ~1200-block range.
- An Etherscan V2 API key. `etherscan` is a **required** explorer; `blockscout` (no API key needed) is recommended as a second explorer for redundancy.
- A Slack bot bearer token.
- A Slack channel for runtime errors.
- A Slack channel for outcome action review.

### Configuration

On a dedicated publisher host, set:

```env
COMPOSE_FILE=validator-publisher.yml
VALIDATOR_PUBLISHER_CHAIN=Mainnet
```

Populate the `VALIDATOR_PUBLISHER_*` variables in `.env`. The publisher container renders its internal `config.json` from these environment variables at startup. No host-mounted `config.json` is required.

For local validation outside Docker, the same config can be rendered with:

```bash
./scripts/render_validator_publisher_config.sh
```

The generated `validator-publisher/config.json` contains secrets and is ignored by git.

Variables used by generated config:

```env
VALIDATOR_PUBLISHER_AGENT_KEY=
VALIDATOR_PUBLISHER_RPC_ALCHEMY_URL=
VALIDATOR_PUBLISHER_RPC_QUICKNODE_URL=
VALIDATOR_PUBLISHER_RPC_INFURA_URL=
VALIDATOR_PUBLISHER_RPC_CHAINSTACK_URL=
VALIDATOR_PUBLISHER_RPC_ANKR_URL=
VALIDATOR_PUBLISHER_RPC_DRPC_URL=
VALIDATOR_PUBLISHER_RPC_SEVENTH_NAME=getblock
VALIDATOR_PUBLISHER_RPC_SEVENTH_URL=
VALIDATOR_PUBLISHER_RPC_LOG_DISCOVERY=
VALIDATOR_PUBLISHER_ETHERSCAN_API_KEY=
VALIDATOR_PUBLISHER_BLOCKSCOUT_URL=https://arbitrum.blockscout.com/api
VALIDATOR_PUBLISHER_SLACK_KEY="Bearer xoxb-..."
VALIDATOR_PUBLISHER_SLACK_ERRORS_CHANNEL=
VALIDATOR_PUBLISHER_SLACK_OUTCOME_ACTIONS_CHANNEL=
VALIDATOR_PUBLISHER_CRIT_MSG_IGNORES='[]'
VALIDATOR_PUBLISHER_FORWARD_FILE_LOGS=true
VALIDATOR_PUBLISHER_FORWARD_LOG_TAIL_LINES=20
VALIDATOR_PUBLISHER_LOG_DISCOVERY_INTERVAL=1
VALIDATOR_PUBLISHER_PRUNE_FILE_LOGS=true
VALIDATOR_PUBLISHER_LOG_RETENTION_DAYS=1
VALIDATOR_PUBLISHER_LOG_PRUNE_INTERVAL=21600
```

`VALIDATOR_PUBLISHER_ETHERSCAN_API_KEY` is **required**: the render script fails without it and always emits the `etherscan` explorer. `VALIDATOR_PUBLISHER_BLOCKSCOUT_URL` adds a recommended second explorer for redundancy.

`VALIDATOR_PUBLISHER_RPC_LOG_DISCOVERY` is a comma-separated list of RPC names (matching the names above) that opt into near-tip `eth_getLogs` deposit discovery, adding `"log_discovery": true` to those RPC entries in the generated config. At least one is required as of the week of 2026-07-27. Only list providers whose plan supports `eth_getLogs` with topic filters over a ~1200-block range; a provider that rejects the method only degrades its own health signal. This is distinct from `VALIDATOR_PUBLISHER_LOG_DISCOVERY_INTERVAL`, which controls container log forwarding.

### Run

Build and start the publisher:

```bash
docker compose -f validator-publisher.yml build --pull
docker compose -f validator-publisher.yml up -d
```

Check status and logs:

```bash
docker compose -f validator-publisher.yml ps
docker compose -f validator-publisher.yml logs -f validator-publisher
```

By default, `VALIDATOR_PUBLISHER_FORWARD_FILE_LOGS=true` forwards the component files under `/opt/validator-publisher/logs` to container stdout with prefixes such as `[validator-publisher:bridge-voter]`. This keeps `docker compose logs` and Docker log shippers useful without persisting a separate raw log volume. Set `VALIDATOR_PUBLISHER_FORWARD_FILE_LOGS=false` to keep only file-based component logs inside the container.

The entrypoint also prunes date-named component log files under `/opt/validator-publisher/logs` when `VALIDATOR_PUBLISHER_PRUNE_FILE_LOGS=true`. By default, it keeps only the current UTC day (`VALIDATOR_PUBLISHER_LOG_RETENTION_DAYS=1`) and runs every six hours (`VALIDATOR_PUBLISHER_LOG_PRUNE_INTERVAL=21600`). The active current-day log file is left in place so the publisher and log forwarder can continue writing and streaming normally.

The container runs the official publisher Visor with:

```bash
--chain Mainnet
--config-path /opt/validator-publisher/config/config.json
--log-dir /opt/validator-publisher/logs
--tmp-dir /opt/validator-publisher/tmp
--acked-outcome-vote-actions-path /opt/validator-publisher/state/acked_outcome_vote_actions.json
```

Only acknowledged outcome vote actions are stored in the named `validator-publisher-state` Docker volume mounted at `/opt/validator-publisher/state`. The generated runtime config, component log files, temporary files, downloaded publisher binaries, and root-level `bridge-voter-state.json` stay in the container filesystem. The entrypoint removes `bridge-voter-state.json` at startup so stale bridge-voter transaction state is not carried across restarts.

On hosts that previously used a root `validator-publisher` volume, preserve `/opt/validator-publisher/state/acked_outcome_vote_actions.json` if it exists, recreate the publisher with the new compose file, then remove the old root volume after confirming the publisher is healthy. Outcome voting does not submit validator actions directly; it posts candidate outcome deploy and settle actions to Slack for validator review.

## AQA Publisher

This repository also includes an optional `aqa-publisher` compose file for publishing the Hyperliquid aligned quote asset rate. The upstream reference implementation is here:
https://github.com/native-markets/aqa-publisher

Hyperliquid recommends active validators publish the AQA rate once per day at 22:00 UTC from a separate machine from the validating node. It is fine to run this on the same non-validator publisher host as `validator-publisher`.

### Runtime Requirements

Prepare the following values outside git:

- A dedicated AQA publisher agent private key approved by the validator.
- Network set to `mainnet`.

The AQA publisher image builds the upstream `native-markets/aqa-publisher` source from `v1.2.0`, which upstream currently marks as the supported release. The default service runs `publish_daemon`; tool-profile services are available for `print_current` and `publish_once`.

### Configuration

On a host that runs only AQA publisher, set:

```env
COMPOSE_FILE=aqa-publisher.yml
```

On the shared publisher host that runs both publisher sidecars, set:

```env
COMPOSE_FILE=validator-publisher.yml:aqa-publisher.yml
```

Populate the AQA variables in `.env`:

```env
AQA_PUBLISHER_VERSION=v1.2.0
AQA_PUBLISHER_PRIVATE_KEY=
AQA_PUBLISHER_NETWORK=mainnet
AQA_PUBLISHER_RUST_LOG=info
```

The compose file maps these to the upstream environment variables:

```env
PUBLISHER_PRIVATE_KEY=${AQA_PUBLISHER_PRIVATE_KEY}
NETWORK=${AQA_PUBLISHER_NETWORK}
RUST_LOG=${AQA_PUBLISHER_RUST_LOG}
```

### Run

Build and start the daemon:

```bash
docker compose -f aqa-publisher.yml build --pull
docker compose -f aqa-publisher.yml up -d
```

Check status and logs:

```bash
docker compose -f aqa-publisher.yml ps
docker compose -f aqa-publisher.yml logs -f aqa-publisher
```

Run the read-only rate check:

```bash
docker compose -f aqa-publisher.yml --profile tools run --rm aqa-print-current
```

Run a one-off publish only after the approved AQA publisher key is configured:

```bash
docker compose -f aqa-publisher.yml --profile tools run --rm aqa-publish-once
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

## Diagnostic & Utility Scripts

This repository includes several diagnostic and utility scripts in the `scripts/` directory for monitoring and managing your Hyperliquid node.

### Active Validator Set Query

Display the active validator set with formatted output. Shows all validators where `isActive == true`, sorted by stake:

```bash
# Use network from .env configuration
./scripts/check_active_set.sh

# Query Mainnet active set
./scripts/check_active_set.sh mainnet

# Query Testnet active set
./scripts/check_active_set.sh testnet
```

**Features:**
- Auto-detects network from `.env` or accepts command-line argument
- Queries the Hyperliquid API for validator summaries
- Displays active validators sorted by stake with formatted output
- Shows total validator count and total staked HYPE

**Sample output:**
```
Hyperliquid Active Validator Set
Network: Mainnet
API Endpoint: https://api.hyperliquid.xyz/info

Active Validators (sorted by stake):

  1. Hyper Foundation 1                       58,654,386.85 HYPE  0x5ac99...
  2. Hyper Foundation 4                       58,394,182.48 HYPE  0xdf35a...
  ...

Total Active Validators: 24
Total Staked: 413,853,515.92 HYPE
```

**Prerequisites:** `curl`, `jq`

### Sync Status Check

Monitor your node's synchronization status by comparing local block height against the public RPC endpoint:

```bash
./scripts/check_sync.sh
```

**Features:**
- Auto-detects network (Mainnet/Testnet) from your `.env` configuration
- Compares local node (`localhost:3001/evm`) with public Hyperliquid RPC
- Shows how many blocks behind (if any)

**Sample output:**
```
Loading environment variables...
Loaded .env file
CHAIN is set to: Mainnet
Local RPC endpoint: http://localhost:3001/evm
Public RPC endpoint: https://rpc.hyperliquid.xyz/evm
Mainnet Local node:   12345678
Mainnet Public head:  12345680
⚠️  Your node is 2 blocks behind
```

**Prerequisites:** `curl`, `jq`

### Network Connectivity Check

Test connectivity to Hyperliquid seed peers to diagnose P2P networking issues:

```bash
./scripts/check_connectivity.sh
```

**Features:**
- Uses `MAINNET_ROOT_IPS` from your `.env` configuration
- Tests ports 4001-4010 for each seed peer IP
- Reports which ports are open or closed

**Sample output:**
```
=== Testing Root IP (1.2.3.4) ===
Port 4001: OPEN
Port 4002: OPEN
Port 4003: CLOSED
...
```

**Prerequisites:** `nc` (netcat), `jq`

### Peer Connections Audit

Audit active P2P connections on your running validator node:

```bash
sudo ./scripts/check_peer_connections.sh
```

**Features:**
- Inspects the consensus container's network namespace
- Shows a table of remote IPs and connection counts per port (4001-4004)
- Sorted by total connection count

**Sample output:**
```
Remote_IP            4001  4002  4003  4004 Total
--------------------
1.2.3.4                  2     1     1     2     6
5.6.7.8                  1     1     1     1     4
...
```

**Prerequisites:** `sudo` access, container must be running

**Note:** This script assumes the container is named `hyperliquid-docker-consensus-1`. If your container has a different name, modify the `CID` variable in the script.

### Wallet Transfer Utility

Transfer USDC or HYPE tokens between wallets on Hyperliquid:

```bash
python3 ./scripts/wallet_transfer.py
```

**Features:**
- Auto-installs required Python dependencies (`hyperliquid-python-sdk`, `eth-account`, `eth-utils`)
- Supports both Mainnet and Testnet
- Interactive CLI for entering transfer details
- Comprehensive error handling with balance verification
- Recipient registration checks

**Interactive prompts:**
1. Enter your private key (without 0x prefix)
2. Enter recipient address
3. Choose token type (USDC or HYPE)
4. Enter amount to transfer
5. Select network (Mainnet or Testnet)
6. Confirm the transfer

**Prerequisites:** Python 3.x, `pip`

**Security note:** This script requires your private key. Only use it on secure, trusted systems. Never share your private key.

## Node Setup

When you first start the node, the container will:
*   **Initialize the node** based on the `CHAIN` variable ("Mainnet" or "Testnet").
*   **Configure the appropriate peers** based on `MAINNET_ROOT_IPS` for Mainnet or `TESTNET_ROOT_IPS` for Testnet.
*   **Download and verify the hl-visor binary** using the official GPG key from `PUB_KEY_URL`.
*   **Keep hl-visor current:** the visor is stored in the data volume, so rebuilding the image does not update it. On every container start the entrypoint downloads the published `hl-visor`, verifies its signature against the same key, and replaces the installed one if it differs (the previous copy is kept as `~/hl-visor.previous`). If the download or verification fails, the installed visor is kept and the node still starts. An outdated visor cannot install newer `hl-node` releases, so the node cannot read the network's current state and stops syncing. Set `VISOR_AUTO_UPDATE=false` to pin the visor.
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

`hl-node` has no Prometheus endpoint (its HTTP port, `EVM_RPC_PORT`, serves only the EVM JSON-RPC on `/evm`, plus `/info` when `--serve-info` is set), so the `consensus` service intentionally carries no `metrics.*` labels. Prometheus metrics come from the optional `monitoring` service ([validaoxyz/hyperliquid-exporter](https://github.com/validaoxyz/hyperliquid-exporter), `hl_exporter`, built from source and pinned by `MONITORING_EXPORTER_VERSION`).

The exporter needs **no node flag change and no node restart**. It mounts the node's data volume read-only and derives metrics from files `hl-node` already writes (`data/node_fast_block_times`, `data/node_slow_block_times`, `data/tcp_traffic`, `data/node_logs/gossip_*`, `data/visor_abci_states`, `data/crit_msg_stats`, ...), so it works on non-validator RPC nodes started with only `--replica-cmds-style recent-actions --serve-eth-rpc`. It tails these files from the end, so metrics appear after it has been running a few seconds.

### Enabling Monitoring

1. **Include the monitoring compose file** in `COMPOSE_FILE` in `.env` (keep `ext-network.yml` in the list on Traefik/Prometheus-discovery hosts so that the exporter has a single network, the external Traefik network, which is what Docker service discovery requires):
   ```env
   COMPOSE_FILE=hyperliquid.yml:ext-network.yml:monitoring.yml
   ```

2. **Configure monitoring settings** in `.env`:
   ```env
   NODE_ALIAS=your-node-name           # A descriptive name for your node
   MONITORING_PORT=8086                # Container port the metrics are served on
   LOG_LEVEL=info                      # Log level for the monitoring service
   MONITORING_PROBE_INFO_ENDPOINT=false  # true ONLY if EXTRA_FLAGS has --serve-info (see below)
   ```

3. **Build and start only the monitoring service.** On a running node use `--no-deps` so that Compose does not reconcile (and possibly recreate, i.e. restart) `consensus`:
   ```bash
   docker compose build monitoring
   docker compose up -d --no-deps monitoring
   ```
   On a fresh install `./hld up -d` starts it together with the node.

`MONITORING_PROBE_INFO_ENDPOINT=true` makes the exporter POST to the node's `/info` endpoint and export `hl_info_*` (including `hl_info_endpoint_up`). The node serves `/info` only with `--serve-info` in `EXTRA_FLAGS`; without that flag `/info` returns 404 and the probe would report `hl_info_endpoint_up == 0` forever, so it is off by default.

### Accessing Metrics

The monitoring service exposes Prometheus metrics on `MONITORING_PORT` (default 8086) at `/metrics`, on the container network only (`expose`, no host port). From the host, `curl http://<container-ip>:8086/metrics`. The service carries the `metrics.*` labels (`metrics.scrape`, `metrics.port`, `metrics.path`, `metrics.instance`, `metrics.network`) used by the central-proxy-docker / Prometheus Docker service discovery, which keeps only the first network of a container.

### Useful signals

These were checked against real node data (non-validator RPC node):

| Question | Metric / query |
|---|---|
| Is the exporter reading the node? | `hl_exporter_ready == 1`, `hl_exporter_monitor_last_tick_seconds{monitor="block"}` |
| Is the node following the chain (block freshness)? | `timestamp(hl_core_latest_block_time) - hl_core_latest_block_time` (seconds behind; use `timestamp()` rather than `time()` to ignore scrape delay) |
| Is the node producing/applying blocks? | `increase(hl_core_block_height[5m])` (about 14 blocks/s, so about 4000 per 5m; 0 means stalled) |
| Block apply time | `hl_metal_apply_duration_milliseconds_*`, `hl_core_block_time_milliseconds_*` (histograms, `state_type` fast/slow) |
| Visor state sync | `hl_visor_reference_lag_seconds`, `hl_visor_last_observation_age_seconds` |
| Peers / traffic | `hl_p2p_peers`, `hl_p2p_sample_age_seconds`, `hl_node_parent_peer_*` |
| Crashes / criticals | `hl_node_child_crashes{reason}`, `hl_node_crits`, `hl_node_replay_events` |
| Disk | `hl_node_disk_free_bytes / hl_node_disk_total_bytes`, `hl_node_disk_subdir_bytes{subdir}` |
| Exporter source errors | `increase(hl_exporter_monitor_errors_total[15m])` |

Suggested alerts: block freshness above 30s for 2m; `increase(hl_core_block_height[5m]) == 0`; `absent(hl_core_latest_block_time)`; `up{job="monitoring"} == 0`.

**Metrics that are not meaningful in this layout** (the exporter runs in its own container, so `/proc` shows neither the node processes nor its sockets): `hl_node_process_*` (e.g. `hl_node_process_up` is always 0) and `hl_p2p_tcp_connections`. Do not alert on them; use cAdvisor container metrics for CPU/memory/restarts of `hyperliquid-consensus-1`. Consensus/validator-only families (`hl_consensus_*`, validator latency) stay at 0 or absent on non-validator nodes, and `hl_core_hardfork_version` reads 0 with v3.1.0.

### Other signals without the exporter

* **RPC probe:** `POST /evm` `eth_blockNumber` (compare against the public RPC, see `scripts/check_sync.sh`) and `eth_syncing`; `net_peerCount` is not implemented by `hl-node`.
* **cAdvisor:** container presence, restarts, CPU and memory of `hyperliquid-consensus-1` (already scraped on the hosts).
* **Logs:** `applied block N` lines in `docker logs` of `consensus` (about every 7 seconds per 100 blocks) show the node is streaming live.

### Visualizing Metrics with Grafana

Create a Grafana dashboard from the metrics above and select your Prometheus data source. A sample public dashboard is available at [ValiDAO Hyperliquid Testnet Monitor](https://hyperliquid-testnet-monitor.validao.xyz/public-dashboards/ff0fbe53299b4f95bb6e9651826b26e0).

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
