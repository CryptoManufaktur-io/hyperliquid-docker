# Hyperliquid Node Docker

This repository provides Docker Compose configurations for running a Hyperliquid node.

It's designed to work with [central-proxy-docker](https://github.com/CryptoManufaktur-io/central-proxy-docker) for Traefik and Prometheus remote write. If you need external network connectivity, include `:ext-network.yml` in your `COMPOSE_FILE` (as set in your `.env` file).

## Quick Setup

1. **Prepare your environment:**
   Copy the default environment file and update your settings:
   ```bash
   cp default.env .env
   nano .env
   ```
   Update values such as `CHAIN` to either "Mainnet" or "Testnet".

2. **Expose RPC Ports (Optional):**
   If you want the node's RPC ports exposed locally, include `rpc-shared.yml` in your `COMPOSE_FILE` within `.env`.

3. **Install Docker (if needed):**
   Run:
   ```bash
   ./hld install
   ```
   This command installs Docker CE if it isn't already installed.

4. **Start the Node:**
   Bring up your Hyperliquid node by running:
   ```bash
   ./hld up
   ```

5. **Software Updates:**
   To update the node software, run:
   ```bash
   ./hld update
   ./hld up
   ```

## Node Setup

When you first start the node, the container will:

- **Initialize the node** based on your selected network (Mainnet or Testnet)
- **Configure the appropriate peers** for Mainnet or Testnet
- **Download and verify the hl-visor binary** using the official GPG key

## Data Pruning

The node includes an automatic pruning service that helps manage the data directory size. The pruning schedule can be configured in the `.env` file.

## Traefik Integration

This setup works with central-proxy-docker's Traefik configuration for secure, proxied access to your Hyperliquid node APIs.

## Version

Hyperliquid Node Docker uses semantic versioning.

This is Hyperliquid Node Docker v1.0.0