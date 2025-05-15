#!/usr/bin/env bash
set -e

# Default node type
: "${NODE_TYPE:=non-validator}"

# Create override_gossip_config.json for mainnet only
if [ -n "$MAINNET_ROOT_IPS" ] && [ "$MAINNET_ROOT_IPS" != "[]" ] && [ "$CHAIN" = "Mainnet" ]; then
  cat > "$HOME/override_gossip_config.json" <<EOF
{ "root_node_ips": $MAINNET_ROOT_IPS, "try_new_peers": false, "chain": "Mainnet" }
EOF
else
  echo "Error: No valid root IPs for chain '$CHAIN'" >&2
  exit 1
fi

# If validator, create node_config.json
if [ "$NODE_TYPE" = "validator" ]; then
  if [ -z "$VALIDATOR_PRIVATE_KEY" ]; then
    echo "Error: VALIDATOR_PRIVATE_KEY is required for validator mode." >&2
    exit 1
  fi
  cat > "$HOME/hl/hyperliquid_data/node_config.json" <<EOF
{ "key": "$VALIDATOR_PRIVATE_KEY" }
EOF
fi

# Base run command
CMD="$HOME/hl-visor run-$NODE_TYPE"

if [ "$ENABLE_EVM_RPC" = "true" ]; then
  CMD="$CMD --serve-eth-rpc"
fi

if [ -n "$EXTRA_FLAGS" ]; then
  CMD="$CMD $EXTRA_FLAGS"
fi

echo "Executing: $CMD"
exec $CMD
