#!/usr/bin/env bash
set -e

# Default node type
: "${NODE_TYPE:=non-validator}"

# Create override_gossip_config.json
if [ "${CHAIN}" = "Mainnet" ]; then
  if [ -n "$MAINNET_ROOT_IPS" ] && [ "$MAINNET_ROOT_IPS" != "[]" ]; then
    # Prepare reserved_peer_ips array
    RESERVED_PEERS="${RESERVED_PEER_IPS:-[]}"
    cat > "$HOME/override_gossip_config.json" <<EOF
{ "root_node_ips": ${MAINNET_ROOT_IPS}, "try_new_peers": false, "chain": "Mainnet", "reserved_peer_ips": ${RESERVED_PEERS} }
EOF
  else
    echo "Error: MAINNET_ROOT_IPS must be set and non-empty when CHAIN=Mainnet" >&2
    exit 1
  fi
fi

if [ "${CHAIN}" = "Testnet" ]; then
  if [ -n "$TESTNET_ROOT_IPS" ] && [ "$TESTNET_ROOT_IPS" != "[]" ]; then
    # Prepare reserved_peer_ips array
    RESERVED_PEERS="${RESERVED_PEER_IPS:-[]}"
    cat > "$HOME/override_gossip_config.json" <<EOF
{ "root_node_ips": ${TESTNET_ROOT_IPS}, "try_new_peers": false, "chain": "Testnet", "reserved_peer_ips": ${RESERVED_PEERS} }
EOF
  else
    echo "Info: Using default peers for CHAIN=Testnet" >&2
    rm -f "$HOME"/override_gossip_config.json
  fi
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
  echo "✅ Wrote validator key to $HOME/hl/hyperliquid_data/node_config.json. This is a validator node 🚨"
else
  rm -rf "$HOME/hl/hyperliquid_data/node_config.json"
  echo "🚨 Removed validator key from $HOME/hl/hyperliquid_data/node_config.json. This is a rpc node 🚨"
fi

# Function to create firewall_ips.json for validators
# This creates the firewall configuration file as specified in the Hyperliquid validator documentation
# The file format is: [ ["ip_address", {"name": "description", "allowed": boolean}], ... ]
# Example output: [ ["43.206.47.239", {"name": "Hyper Foundation 1", "allowed": true}] ]
create_firewall_config() {
  local firewall_dir="$HOME/hl/file_mod_time_tracker"
  local firewall_file="$firewall_dir/firewall_ips.json"

  # Create directory if it doesn't exist
  mkdir -p "$firewall_dir"

  if [ -n "$FIREWALL_IPS" ] && [ "$FIREWALL_IPS" != "[]" ]; then
    echo "Creating firewall configuration at $firewall_file"

    # Validate JSON format first
    if ! echo "$FIREWALL_IPS" | jq . >/dev/null 2>&1; then
      echo "❌ Error: FIREWALL_IPS contains invalid JSON format" >&2
      exit 1
    fi

    # Parse the FIREWALL_IPS JSON and convert to the required format: [ ["ip", {"name": "...", "allowed": true}], ... ]
    if echo "$FIREWALL_IPS" | jq 'map([.ip, {"name": .name, "allowed": .allowed}])' > "$firewall_file" && [ -s "$firewall_file" ]; then
      echo "✅ Successfully created firewall configuration"
      echo "Firewall IPs configured:"
      jq -r '.[] | "  \(.[0]) - \(.[1].name) (allowed: \(.[1].allowed))"' "$firewall_file"
    else
      echo "❌ Error: Failed to create firewall configuration file" >&2
      echo "Expected FIREWALL_IPS format: [{\"ip\": \"1.2.3.4\", \"name\": \"Node Name\", \"allowed\": true}, ...]" >&2
      exit 1
    fi
  else
    echo "No firewall IPs configured (FIREWALL_IPS is empty or not set)"
    # Create empty array if no IPs are specified
    echo "[]" > "$firewall_file"
    echo "Created empty firewall configuration at $firewall_file"
  fi
}

# Create firewall configuration for validators or when FIREWALL_IPS is explicitly set
# This is required for mainnet validators to manage DDOS protection and peer connectivity
if [ -n "$FIREWALL_IPS" ]; then
  create_firewall_config
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
