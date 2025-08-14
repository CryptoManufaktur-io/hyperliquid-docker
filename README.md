# Hyperliquid Node Docker

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Docker](https://img.shields.io/badge/Docker-20.10%2B-blue)](https://docs.docker.com/get-docker/)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2.0%2B-blue)](https://docs.docker.com/compose/)

A comprehensive Docker Compose setup for running Hyperliquid blockchain nodes with built-in monitoring, automated data pruning, and management utilities.

## 🚀 Features

- **Full Node Support**: Run both validator and non-validator nodes
- **Multi-Network**: Support for Mainnet and Testnet
- **Built-in Monitoring**: Prometheus metrics and Grafana dashboards
- **Automated Pruning**: Configurable data retention management
- **Management Tools**: CLI utilities and validator information queries
- **Traefik Integration**: Ready for reverse proxy and TLS termination
- **Easy Updates**: One-command software updates

## 📋 Table of Contents

- [Quick Setup](#quick-setup)
- [Configuration](#configuration)
- [Node Operations](#node-operations)
- [Tools and Utilities](#tools-and-utilities)
- [Monitoring](#monitoring)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [FAQ](#faq)

This repository is designed to work with [central-proxy-docker](https://github.com/CryptoManufaktur-io/central-proxy-docker) for Traefik and Prometheus remote write integration.

## Quick Setup

### Prerequisites

- Docker 20.10+ and Docker Compose 2.0+
- 4+ CPU cores, 8GB+ RAM, 500GB+ SSD storage
- Open internet connectivity on P2P ports

### 1. Prepare Your Environment

Copy the default environment file and customize your settings:

```bash
cp default.env .env
nano .env  # or use your preferred editor
```

**Essential Configuration Variables:**

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `CHAIN` | Network to join | `"Mainnet"` or `"Testnet"` | ✅ |
| `NODE_TYPE` | Node operation mode | `"non-validator"` or `"validator"` | ✅ |
| `USERNAME` | Container user | `hyperliquid` | ✅ |
| `ENABLE_EVM_RPC` | Enable EVM RPC endpoint | `true` or `false` | ✅ |
| `P2P_PORT_RANGE` | P2P communication ports | `4000-4010` | ✅ |
| `EVM_RPC_PORT` | EVM RPC port | `3001` | ✅ |
| `MAINNET_ROOT_IPS` | Mainnet seed peers (JSON) | See default.env | ⚠️  |
| `TESTNET_ROOT_IPS` | Testnet seed peers (JSON) | See default.env | ⚠️  |
| `VALIDATOR_PRIVATE_KEY` | Validator private key | `0x123...` | ⚠️  |

> **⚠️ Note**: `MAINNET_ROOT_IPS` is required for Mainnet. `VALIDATOR_PRIVATE_KEY` is required only for validator nodes.

### 2. Configure Network Access (Optional)

**For EVM RPC Exposure:**
To expose the node's EVM RPC port directly on your host machine:

```env
# .env
COMPOSE_FILE=hyperliquid.yml:rpc-shared.yml
```

**For Traefik Integration:**
For external network connectivity and reverse proxy:

```env
# .env
COMPOSE_FILE=hyperliquid.yml:ext-network.yml:monitoring.yml
DOMAIN=your-domain.com
RPC_HOST=hyperliquid
```

### 3. Install Dependencies (if needed)

```bash
# Install Docker and services (requires sudo)
sudo ./hld install
```

This installs Docker CE and systemd service if not already present.

### 4. Start Your Node

```bash
# Start all services
./hld up -d

# Verify services are running
./hld logs
```

### 5. Monitor Initial Sync

```bash
# Check real-time logs
./hld logs -f consensus

# Check sync status (requires EVM RPC enabled)
./scripts/check_sync.sh
```

### 6. Update Software

```bash
# Update node software and Docker images
./hld update
./hld up -d --remove-orphans
```

## Configuration

### Environment Variables Reference

This section provides detailed explanations of all configuration options in your `.env` file.

#### Core Node Settings

```env
# Network Configuration
CHAIN=Mainnet                    # "Mainnet" or "Testnet"
NODE_TYPE=non-validator          # "non-validator" or "validator"
USERNAME=hyperliquid             # Container user (default: hyperliquid)

# Node Features
ENABLE_EVM_RPC=true             # Enable ETH-compatible RPC endpoint
EXTRA_FLAGS="--replica-cmds-style recent-actions"  # Additional hl-visor flags
```

#### Network and Ports

```env
# Port Configuration
P2P_PORT_RANGE=4000-4010        # P2P communication port range
EVM_RPC_PORT=3001               # EVM RPC endpoint port

# Peer Configuration
MAINNET_ROOT_IPS='[{"Ip": "57.182.103.24"},{"Ip": "46.105.222.166"},{"Ip": "8.211.133.129"}]'
TESTNET_ROOT_IPS='[{"Ip": "13.213.240.190"},{"Ip": "146.59.69.10"}]'
```

> **📝 Note**: Root IPs are seed peers for initial network connection. Mainnet IPs are required for Mainnet operation.

#### Docker Compose Configuration

```env
# Service Composition
COMPOSE_FILE=hyperliquid.yml:monitoring.yml  # Base services + monitoring

# Available compose files:
# - hyperliquid.yml      (core node services)
# - monitoring.yml       (metrics and monitoring)
# - rpc-shared.yml      (expose EVM RPC on host)
# - ext-network.yml     (Traefik integration)
```

#### Monitoring Settings

```env
# Monitoring Configuration
NODE_ALIAS=local                # Descriptive name for your node
MONITORING_PORT=8086           # Prometheus metrics port
LOG_LEVEL=info                 # Logging verbosity
```

#### Traefik Integration (Advanced)

```env
# Reverse Proxy Settings
DOMAIN=example.com             # Your domain name
RPC_HOST=hyperliquid          # Subdomain for RPC access
RPC_LB=hyperliquid-lb         # Load balancer label
DOCKER_EXT_NETWORK=traefik_default  # External Docker network
```

#### Validator-Specific Settings

```env
# Validator Configuration (Required for NODE_TYPE=validator)
VALIDATOR_PRIVATE_KEY=0x1234...  # Your validator private key
```

> **🔒 Security Warning**: Never commit validator private keys to version control. Generate with `openssl rand -hex 32`.

### Docker Compose Files Explained

| File | Purpose | When to Include |
|------|---------|----------------|
| `hyperliquid.yml` | Core node services | Always (base) |
| `monitoring.yml` | Prometheus metrics | Recommended for production |
| `rpc-shared.yml` | Host port exposure | When external RPC access needed |
| `ext-network.yml` | Traefik integration | When using reverse proxy |

### Configuration Examples

**Basic Non-Validator (Testnet):**
```env
CHAIN=Testnet
NODE_TYPE=non-validator
COMPOSE_FILE=hyperliquid.yml:monitoring.yml
```

**Production Validator (Mainnet):**
```env
CHAIN=Mainnet
NODE_TYPE=validator
VALIDATOR_PRIVATE_KEY=0x...
COMPOSE_FILE=hyperliquid.yml:monitoring.yml:ext-network.yml
DOMAIN=your-domain.com
```

**Development Setup with Exposed RPC:**
```env
CHAIN=Testnet
NODE_TYPE=non-validator
COMPOSE_FILE=hyperliquid.yml:rpc-shared.yml:monitoring.yml
```

## Node Operations

### Node Lifecycle Management

**Start Services:**
```bash
./hld up -d                    # Start all configured services
./hld up -d consensus          # Start specific service
```

**Stop Services:**
```bash
./hld down                     # Stop all services
./hld stop consensus           # Stop specific service
```

**Restart Services:**
```bash
./hld restart                  # Restart all services
./hld restart consensus        # Restart specific service
```

**View Status:**
```bash
./hld logs                     # View recent logs
./hld logs -f consensus        # Follow logs in real-time
./hld logs --timestamps        # Include timestamps
docker compose ps              # Service status overview
```

### Node Initialization Process

When you first start the node, the system automatically:

1. **Downloads hl-visor binary** and verifies with GPG signature
2. **Configures network peers** based on `CHAIN` and root IPs settings
3. **Creates validator config** (if `NODE_TYPE=validator`)
4. **Starts blockchain sync** from network peers
5. **Enables monitoring** (if monitoring.yml included)

### Accessing Your Node

**Container Shell Access:**
```bash
# Access running consensus container
docker compose exec consensus bash

# Run commands in container
docker compose exec consensus hl-visor --help
```

**Direct Binary Access:**
```bash
# Interactive mode with full environment
docker compose --profile tools run --rm cli

# Run specific commands
docker compose --profile tools run --rm cli hl-visor --version
```

### Node Synchronization

**Check Sync Status:**
```bash
# Compare local vs network block height
./scripts/check_sync.sh

# Manual RPC query (if EVM RPC enabled)
curl -X POST http://localhost:3001/evm \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

**Sync Indicators:**
- **✅ Synced**: Local block height matches or is close to network
- **⚠️ Syncing**: Local height is behind network (normal during initial sync)
- **❌ Issues**: No height progress for extended period

### Data Management

**Disk Usage Monitoring:**
```bash
# Check data volume usage
docker compose exec consensus df -h /home/hyperliquid/hl

# View largest directories
docker compose exec consensus du -sh /home/hyperliquid/hl/*
```

**Data Pruning:**
The pruner service automatically runs daily at 3 AM to remove old blockchain data:
- Uses official Hyperliquid pruning script
- Maintains node functionality while reducing disk usage
- Configurable schedule via cron in pruner container

**Manual Operations:**
```bash
# Restart with fresh sync (destructive!)
./hld down
docker volume rm hyperliquid-docker_consensus-data
./hld up -d
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

## Security

### Validator Security Best Practices

**Private Key Management:**
```bash
# Generate a secure private key (DO NOT use for production without additional security)
openssl rand -hex 32

# Store in secure location outside of repository
export VALIDATOR_PRIVATE_KEY="0x$(openssl rand -hex 32)"
echo "VALIDATOR_PRIVATE_KEY=$VALIDATOR_PRIVATE_KEY" >> .env
```

> **🔐 Critical Security Guidelines:**
> - Never commit private keys to version control
> - Use hardware security modules (HSM) for production validators
> - Regularly rotate keys following network guidelines
> - Implement proper key backup and recovery procedures

**Network Security:**

```bash
# Firewall configuration (example for Ubuntu/Debian)
sudo ufw allow 22/tcp                    # SSH
sudo ufw allow 4000:4010/tcp            # P2P ports
sudo ufw allow 3001/tcp                 # EVM RPC (if needed externally)
sudo ufw enable
```

**Container Security:**
- Containers run as non-root user (`hyperliquid`)
- Data volumes use appropriate permissions
- Regular security updates via `./hld update`

**Monitoring Security:**
- Metrics endpoints should be internal-only
- Use Traefik with TLS for external access
- Implement proper authentication for Grafana dashboards

### Production Deployment Checklist

**Pre-Deployment:**
- [ ] Secure private key generation and storage
- [ ] Firewall rules configured
- [ ] Monitoring and alerting setup
- [ ] Backup procedures established
- [ ] Emergency procedures documented

**Post-Deployment:**
- [ ] Sync status verified
- [ ] Metrics collection working
- [ ] Log aggregation configured
- [ ] Performance baselines established
- [ ] Regular maintenance scheduled

**Ongoing Security:**
- [ ] Regular software updates
- [ ] Security monitoring alerts
- [ ] Incident response procedures
- [ ] Compliance with network governance

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

## Advanced Configuration

### Traefik Integration

For production deployments with external access, include `:ext-network.yml` in your `COMPOSE_FILE` and configure domain settings:

```env
# .env
COMPOSE_FILE=hyperliquid.yml:monitoring.yml:ext-network.yml
DOMAIN=your-domain.com
RPC_HOST=hyperliquid
RPC_LB=hyperliquid-lb
DOCKER_EXT_NETWORK=traefik_default
```

This provides secure, proxied access (HTTPS) to the node's EVM RPC endpoint through Traefik.

### Custom Docker Compose Configurations

**Creating Custom Compose Files:**
```yaml
# custom.yml - Example custom configuration
services:
  consensus:
    environment:
      - CUSTOM_VAR=value
    volumes:
      - ./custom-config:/custom
```

**Including Custom Files:**
```env
COMPOSE_FILE=hyperliquid.yml:monitoring.yml:custom.yml
```

### Environment Variables Override

**Runtime Environment Variables:**
```bash
# Override environment variables at runtime
CHAIN=Testnet NODE_TYPE=validator ./hld up -d

# Pass additional Docker Compose variables
COMPOSE_PROJECT_NAME=my-node ./hld up -d
```

### Data Directory Customization

**Custom Data Locations:**
```bash
# Create custom bind mounts (edit docker-compose file)
# WARNING: Advanced users only
volumes:
  - /path/to/custom/data:/home/hyperliquid/hl
```

### Performance Tuning

**Resource Limits (Production):**
```yaml
# Add to compose override
services:
  consensus:
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'
          memory: 4G
```

**Network Optimization:**
```env
# Adjust P2P connections in EXTRA_FLAGS
EXTRA_FLAGS="--replica-cmds-style recent-actions --max-peers 50"
```

### Multi-Node Deployment

**Running Multiple Nodes:**
1. Create separate directories for each node
2. Copy configuration files
3. Modify ports in each `.env` file
4. Use different `COMPOSE_PROJECT_NAME`

```bash
# Node 1
mkdir node1 && cd node1
cp ../default.env .env
# Edit .env: P2P_PORT_RANGE=4000-4010, EVM_RPC_PORT=3001

# Node 2
mkdir ../node2 && cd ../node2
cp ../default.env .env
# Edit .env: P2P_PORT_RANGE=4020-4030, EVM_RPC_PORT=3002
```

## Deployment Considerations

### Hardware Requirements

| Component | Minimum | Recommended | Enterprise |
|-----------|---------|-------------|------------|
| CPU | 4 cores | 8 cores | 16+ cores |
| RAM | 8GB | 16GB | 32GB+ |
| Storage | 500GB SSD | 1TB NVMe | 2TB+ NVMe |
| Network | 100 Mbps | 1 Gbps | 10 Gbps |

### Network Configuration

**Firewall Setup:**
```bash
# Required ports for Hyperliquid
sudo ufw allow 4000:4010/tcp    # P2P communication
sudo ufw allow 3001/tcp         # EVM RPC (if external access needed)
sudo ufw allow 8086/tcp         # Monitoring (internal only recommended)
```

**Network Topology Considerations:**
- Validators: Direct internet connection preferred
- Non-validators: Can operate behind NAT with port forwarding
- Load balancers: Consider multiple RPC endpoints for high availability

### Production Deployment Checklist

**Infrastructure:**
- [ ] Hardware meets recommended specifications
- [ ] Network configuration completed and tested
- [ ] Firewall rules configured and verified
- [ ] Monitoring and alerting systems deployed
- [ ] Backup and recovery procedures established

**Security:**
- [ ] Private keys generated and stored securely
- [ ] Access controls implemented
- [ ] SSL/TLS certificates configured (if using Traefik)
- [ ] Regular security update schedule established
- [ ] Incident response procedures documented

**Operational:**
- [ ] Initial sync completed and verified
- [ ] Performance baselines established
- [ ] Log aggregation and analysis setup
- [ ] Regular maintenance windows scheduled
- [ ] Emergency contact procedures established

### Service Profiles and Scaling

**Available Profiles:**
- **Default**: `consensus` and `pruner` services
- **Tools**: Add `--profile tools` for CLI and validator utilities
- **Monitoring**: Include `:monitoring.yml` for metrics collection
- **External**: Include `:ext-network.yml` for Traefik integration

**Scaling Considerations:**
- Data growth: Plan for 10-20GB/month storage growth
- Network bandwidth: Monitor P2P and RPC traffic patterns
- CPU utilization: Track during high network activity periods
- Memory usage: Monitor for memory leaks or excessive consumption

## Troubleshooting

### Common Issues and Solutions

#### Sync Issues

**Problem**: Node is not syncing or stuck at specific block
```bash
# Diagnosis
./scripts/check_sync.sh
./hld logs consensus | grep -i "sync\|error\|height"

# Solutions
1. Check peer connectivity
./hld logs consensus | grep -i "peer"

2. Verify network configuration
docker compose exec consensus cat /home/hyperliquid/override_gossip_config.json

3. Restart consensus service
./hld restart consensus
```

#### Port Conflicts

**Problem**: Cannot bind to ports (address already in use)
```bash
# Find processes using ports
sudo netstat -tulpn | grep :4000
sudo netstat -tulpn | grep :3001

# Kill conflicting processes or change ports in .env
```

#### Disk Space Issues

**Problem**: Node stops due to insufficient disk space
```bash
# Check disk usage
df -h
docker system df

# Clean up Docker resources
docker system prune -a
docker volume prune

# Verify pruner is running
./hld logs pruner
```

#### Permission Errors

**Problem**: File permission denied errors
```bash
# Check and fix data directory permissions
sudo chown -R $(id -u):$(id -g) hyperliquid-data/
docker compose exec consensus ls -la /home/hyperliquid/
```

#### Container Startup Failures

**Problem**: Services fail to start
```bash
# Check service status and logs
docker compose ps
./hld logs consensus
./hld logs monitoring

# Common solutions:
1. Verify .env configuration
2. Check Docker daemon status: sudo systemctl status docker
3. Restart Docker: sudo systemctl restart docker
4. Pull latest images: ./hld update
```

### Diagnostic Commands

```bash
# System Health Check
./hld logs --tail=50 consensus        # Recent logs
docker compose top                    # Resource usage
docker system df                      # Disk usage
docker stats                         # Real-time stats

# Network Connectivity
docker compose exec consensus ping 8.8.8.8
docker compose exec consensus curl -s https://api.hyperliquid.xyz/info

# Node Status
./scripts/check_sync.sh              # Sync status
docker compose exec consensus hl-visor --version
```

### Log Analysis

**Important Log Patterns:**
```bash
# Sync progress
./hld logs consensus | grep -i "height\|block"

# Error detection
./hld logs consensus | grep -i "error\|fail\|panic"

# Network issues
./hld logs consensus | grep -i "peer\|connection\|timeout"

# Performance monitoring
./hld logs consensus | grep -i "memory\|cpu\|disk"
```

### Recovery Procedures

**Full Node Reset (Nuclear Option):**
```bash
# WARNING: This deletes all blockchain data
./hld down
docker volume rm hyperliquid-docker_consensus-data
./hld up -d
```

**Configuration Reset:**
```bash
# Reset to default configuration
cp default.env .env
# Edit .env with your settings
./hld restart
```

## FAQ

### General Questions

**Q: How long does initial sync take?**
A: Initial sync time depends on network (Mainnet ~hours to days, Testnet ~minutes to hours) and hardware specs. Monitor with `./scripts/check_sync.sh`.

**Q: Can I run multiple nodes on the same machine?**
A: Yes, but each needs unique ports and separate directories. Copy the entire setup to different folders and modify `.env` port configurations.

**Q: What are the minimum hardware requirements?**
A: 4 CPU cores, 8GB RAM, 500GB SSD storage minimum. More resources improve performance and reliability.

**Q: How do I backup my node?**
A: Backup your `.env` file and validator private key. Blockchain data can be re-synced. For faster recovery, backup the data volume.

### Validator Questions

**Q: How do I generate a validator private key securely?**
A: Use `openssl rand -hex 32` for testing. For production, use hardware security modules or secure key generation practices.

**Q: Can I migrate my validator to a new server?**
A: Yes, stop the old node, transfer your private key and configuration, start the new node. Minimize downtime to avoid penalties.

**Q: How do I check my validator status?**
A: Use `docker compose --profile tools run --rm validator-info | jq '.[] | select(.address == "YOUR_ADDRESS")'`

### Network and Configuration

**Q: Which compose files should I use?**
A:
- Basic: `hyperliquid.yml`
- With monitoring: `hyperliquid.yml:monitoring.yml`
- External RPC: `hyperliquid.yml:rpc-shared.yml`
- Production: `hyperliquid.yml:monitoring.yml:ext-network.yml`

**Q: How do I expose RPC to external networks?**
A: Include `:rpc-shared.yml` in `COMPOSE_FILE` or use `:ext-network.yml` with Traefik for secure access.

**Q: Can I change ports after initial setup?**
A: Yes, update `.env` ports and restart: `./hld down && ./hld up -d`

### Troubleshooting Questions

**Q: Node shows as synced but RPC returns old blocks**
A: Check if EVM RPC is enabled (`ENABLE_EVM_RPC=true`) and restart if needed.

**Q: High CPU/memory usage**
A: Monitor with `docker stats`. Consider reducing concurrent connections or upgrading hardware.

**Q: Peers not connecting**
A: Verify firewall settings, check root IPs configuration, ensure internet connectivity on P2P ports.

## Advanced Configuration

## Version

Hyperliquid Node Docker uses semantic versioning.

This is Hyperliquid Node Docker v1.3.0

## 📚 Additional Documentation

- **[Docker Configuration Guide](docs/DOCKER_CONFIGURATION.md)** - Detailed explanation of Docker Compose files and customization
- **[Security Policy](SECURITY.md)** - Security best practices and vulnerability reporting
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute to this project

## 📝 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/CryptoManufaktur-io/hyperliquid-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/CryptoManufaktur-io/hyperliquid-docker/discussions)
- **Documentation**: Check the docs/ directory for detailed guides