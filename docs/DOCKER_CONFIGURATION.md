# Docker Configuration Guide

This guide explains the Docker Compose configuration files used in Hyperliquid Node Docker and how to customize them.

## 📋 Overview

The project uses multiple Docker Compose files to provide modular functionality:

| File | Purpose | Services Included |
|------|---------|-------------------|
| `hyperliquid.yml` | Core node services | `consensus`, `pruner` |
| `monitoring.yml` | Metrics collection | `monitoring` |
| `rpc-shared.yml` | Host port exposure | Port mapping for EVM RPC |
| `ext-network.yml` | Traefik integration | External network labels |

## 🔧 Configuration Files

### hyperliquid.yml (Core Services)

**consensus service:**
- Runs the main Hyperliquid node binary (`hl-visor`)
- Handles P2P networking and blockchain synchronization
- Exposes configurable port ranges for P2P communication
- Mounts persistent data volume for blockchain data

**pruner service:**
- Automated blockchain data cleanup
- Runs on cron schedule (daily at 3 AM)
- Uses official Hyperliquid pruning scripts
- Shares data volume with consensus service

**Key Configuration:**
```yaml
services:
  consensus:
    image: hyperliquid:latest
    environment:
      - CHAIN=${CHAIN}
      - NODE_TYPE=${NODE_TYPE}
      - USERNAME=${USERNAME}
      - ENABLE_EVM_RPC=${ENABLE_EVM_RPC}
    ports:
      - "${P2P_PORT_RANGE}:4000-4010"
    volumes:
      - consensus-data:/home/${USERNAME}/hl
```

### monitoring.yml (Metrics Collection)

**monitoring service:**
- Runs hyperliquid-exporter for Prometheus metrics
- Exposes metrics on configurable port
- Provides node health and performance data
- Integrates with Grafana dashboards

**Key Configuration:**
```yaml
services:
  monitoring:
    image: validaoxyz/hyperliquid-exporter:latest
    environment:
      - NODE_ALIAS=${NODE_ALIAS}
      - LOG_LEVEL=${LOG_LEVEL}
    ports:
      - "${MONITORING_PORT}:8086"
```

### rpc-shared.yml (RPC Port Exposure)

**Purpose:**
- Exposes EVM RPC port directly on host machine
- Allows external applications to connect to node RPC
- Useful for development and direct API access

**Key Configuration:**
```yaml
services:
  consensus:
    ports:
      - "${EVM_RPC_PORT}:3001"
```

### ext-network.yml (Traefik Integration)

**Purpose:**
- Configures services for external Docker network
- Adds Traefik labels for reverse proxy
- Enables secure HTTPS access via domain names
- Integrates with central-proxy-docker setup

**Key Configuration:**
```yaml
services:
  consensus:
    networks:
      - default
      - ${DOCKER_EXT_NETWORK}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.${RPC_HOST}.rule=Host(`${RPC_HOST}.${DOMAIN}`)"
```

## 🚀 Usage Patterns

### Basic Node (Testnet)
```env
COMPOSE_FILE=hyperliquid.yml
CHAIN=Testnet
NODE_TYPE=non-validator
```

### Production Node with Monitoring
```env
COMPOSE_FILE=hyperliquid.yml:monitoring.yml
CHAIN=Mainnet
NODE_TYPE=validator
```

### Development with External RPC
```env
COMPOSE_FILE=hyperliquid.yml:rpc-shared.yml
CHAIN=Testnet
EVM_RPC_PORT=3001
```

### Full Production Setup
```env
COMPOSE_FILE=hyperliquid.yml:monitoring.yml:ext-network.yml
CHAIN=Mainnet
DOMAIN=your-domain.com
```

## 🔧 Customization

### Creating Custom Compose Files

**custom-development.yml example:**
```yaml
version: '3.8'

services:
  consensus:
    environment:
      # Override for development
      - LOG_LEVEL=debug
      - EXTRA_FLAGS=--dev-mode
    volumes:
      # Add development tools
      - ./dev-tools:/dev-tools
      
  dev-tools:
    image: alpine:latest
    command: sleep infinity
    volumes:
      - consensus-data:/data
    profiles:
      - dev
```

**Usage:**
```env
COMPOSE_FILE=hyperliquid.yml:custom-development.yml
```

### Environment Variable Overrides

**Runtime Overrides:**
```bash
# Override specific variables
CHAIN=Testnet NODE_TYPE=validator ./hld up -d

# Use different compose project
COMPOSE_PROJECT_NAME=test-node ./hld up -d
```

**Custom Environment Files:**
```bash
# Use custom environment file
cp default.env test.env
# Edit test.env
./hld --env-file test.env up -d
```

### Volume Customization

**Custom Data Paths:**
```yaml
# In custom compose file
services:
  consensus:
    volumes:
      - /custom/path/consensus-data:/home/${USERNAME}/hl
      - /custom/path/config:/home/${USERNAME}/config
```

**Named Volume Configuration:**
```yaml
volumes:
  consensus-data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /custom/blockchain/data
```

## 🔍 Service Dependencies

### Dependency Graph
```
consensus (core)
├── pruner (data management)
├── monitoring (metrics)
└── External Network
    └── Traefik (reverse proxy)
```

### Startup Order
1. **consensus**: Must start first (core service)
2. **pruner**: Depends on consensus for shared volume
3. **monitoring**: Independent, can start in parallel
4. **External services**: Start after consensus is ready

### Health Checks

**Consensus Health:**
```yaml
services:
  consensus:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 🛠️ Troubleshooting

### Common Configuration Issues

**Port Conflicts:**
```bash
# Check port usage
netstat -tulpn | grep :4000
docker compose ps

# Solution: Change ports in .env
P2P_PORT_RANGE=5000-5010
EVM_RPC_PORT=3002
```

**Volume Permission Issues:**
```bash
# Check volume permissions
docker compose exec consensus ls -la /home/hyperliquid/

# Fix permissions
sudo chown -R 1000:1000 /var/lib/docker/volumes/hyperliquid-docker_consensus-data
```

**Network Configuration:**
```bash
# Inspect networks
docker network ls
docker network inspect hyperliquid-docker_default

# Reset networks
docker compose down
docker network prune
docker compose up -d
```

### Debugging Commands

**Service Inspection:**
```bash
# View effective compose configuration
docker compose config

# Check specific service config
docker compose config consensus

# Validate compose files
docker compose -f hyperliquid.yml config --quiet
```

**Resource Monitoring:**
```bash
# Monitor resource usage
docker stats

# Check service logs
docker compose logs consensus
docker compose logs monitoring

# View system events
docker system events
```

## 📚 Best Practices

### Configuration Management
- Keep `.env` files in version control (without secrets)
- Use separate environment files for different deployments
- Document any custom configurations
- Regularly backup configuration files

### Security Considerations
- Never expose RPC ports publicly without authentication
- Use Traefik with TLS for external access
- Regularly update Docker images
- Monitor for security advisories

### Performance Optimization
- Use SSD storage for data volumes
- Configure appropriate resource limits
- Monitor and tune container resource usage
- Consider using Docker Compose profiles for different use cases

### Maintenance
- Regularly run `docker system prune` to clean up
- Monitor disk usage and configure pruning appropriately
- Keep Docker and Docker Compose updated
- Test configuration changes in non-production environments first