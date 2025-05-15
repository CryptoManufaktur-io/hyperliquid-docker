#!/bin/sh

echo "Starting entrypoint script..."
echo "Selected CHAIN: $CHAIN"

# Debug: Log COMPOSE_FILE
echo "COMPOSE_FILE: $COMPOSE_FILE"

# Determine NODE_TYPE based on environment variable or COMPOSE_FILE
if [ -z "$NODE_TYPE" ]; then
  if [ "$COMPOSE_FILE" = "hyperliquid-validator.yml" ]; then
    NODE_TYPE="validator"
  elif [ "$COMPOSE_FILE" = "hyperliquid-non-validator.yml" ]; then
    NODE_TYPE="non-validator"
  else
    echo "Warning: NODE_TYPE not set and COMPOSE_FILE is not recognized. Defaulting to 'non-validator'."
    NODE_TYPE="non-validator"
  fi
fi

# Debug: Log the selected NODE_TYPE
echo "NODE_TYPE: $NODE_TYPE"

# Determine which visor binary to use and link it
VISOR_BINARY="/home/hluser/hl-visor-$(echo "$CHAIN" | tr "[:upper:]" "[:lower:]")"
if [ ! -f "$VISOR_BINARY" ]; then
  echo "Error: Visor binary $VISOR_BINARY not found!"
  exit 1
fi
ln -sf "$VISOR_BINARY" /home/hluser/hl-visor
echo "Using visor binary: $VISOR_BINARY"

# Set ROOT_IPS and TRY_NEW_PEERS based on CHAIN
if [ "$CHAIN" = "Mainnet" ]; then
  ROOT_IPS="$MAINNET_ROOT_IPS"
  TRY_NEW_PEERS="$GOSSIP_TRY_NEW_PEERS_MAINNET"
elif [ "$CHAIN" = "Testnet" ]; then
  ROOT_IPS="$TESTNET_ROOT_IPS"
  TRY_NEW_PEERS="$GOSSIP_TRY_NEW_PEERS_TESTNET"
else
  echo "Error: Invalid CHAIN specified: $CHAIN. Must be 'Mainnet' or 'Testnet'."
  exit 1
fi

# Create visor.json
echo "{\"chain\": \"$CHAIN\"}" > /home/hluser/visor.json
echo "Created /home/hluser/visor.json with content: $(cat /home/hluser/visor.json)"

# Debug: Log ROOT_IPS and TRY_NEW_PEERS
echo "ROOT_IPS: $ROOT_IPS"
echo "TRY_NEW_PEERS: $TRY_NEW_PEERS"

# Ensure TRY_NEW_PEERS has a valid value
if [ -z "$TRY_NEW_PEERS" ]; then
  TRY_NEW_PEERS=true
fi

# Create override_gossip_config.json
if [ -n "$ROOT_IPS" ] && [ "$ROOT_IPS" != "[]" ]; then
  echo "{ \"root_node_ips\": $ROOT_IPS, \"try_new_peers\": $TRY_NEW_PEERS, \"chain\": \"$CHAIN\" }" > /home/hluser/override_gossip_config.json
  echo "Created /home/hluser/override_gossip_config.json with content: $(cat /home/hluser/override_gossip_config.json)"
else
  echo "Error: No valid root IPs defined for $CHAIN or ROOT_IPS is empty. Cannot proceed."
  exit 1
fi

# Debug: Log the VALIDATOR_PRIVATE_KEY
echo "VALIDATOR_PRIVATE_KEY: $VALIDATOR_PRIVATE_KEY"

# Create node_config.json only for validator mode
if [ "$NODE_TYPE" = "validator" ]; then
  if [ -n "$VALIDATOR_PRIVATE_KEY" ]; then
    echo "{\"key\": \"$VALIDATOR_PRIVATE_KEY\"}" > /home/hluser/hl/hyperliquid_data/node_config.json
    echo "Created /home/hluser/hl/hyperliquid_data/node_config.json with content: $(cat /home/hluser/hl/hyperliquid_data/node_config.json)"
  else
    echo "Error: VALIDATOR_PRIVATE_KEY is not set but NODE_TYPE is 'validator'. Cannot proceed."
    exit 1
  fi
else
  echo "NODE_TYPE is non-validator. Skipping node_config.json creation."
fi

# Execute the hl-visor command
CMD="/home/hluser/hl-visor run-$NODE_TYPE --replica-cmds-style recent-actions"
if [ "$ENABLE_RPC" = "true" ]; then
  CMD="$CMD --serve-eth-rpc"
fi
CMD="$CMD $EXTRA_FLAGS"
echo "Executing: exec $CMD"
exec $CMD
