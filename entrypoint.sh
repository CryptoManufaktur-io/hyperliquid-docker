#!/bin/sh

echo "Starting entrypoint script..."
echo "Selected CHAIN: $CHAIN"

# Determine which visor binary to use and link it
VISOR_BINARY="/home/hluser/hl-visor-$(echo "$CHAIN" | tr "[:upper:]" "[:lower:]")"
if [ ! -f "$VISOR_BINARY" ]; then
  echo "Error: Visor binary $VISOR_BINARY not found!"
  exit 1
fi
ln -sf "$VISOR_BINARY" /home/hluser/hl-visor
echo "Using visor binary: $VISOR_BINARY"

# Set RUN_MODE based on COMPOSE_FILE or environment variable
if [ -z "$RUN_MODE" ]; then
  if [ "$COMPOSE_FILE" = "hyperliquid-validator.yml" ]; then
    RUN_MODE="validator"
  elif [ "$COMPOSE_FILE" = "hyperliquid-non-validator.yml" ]; then
    RUN_MODE="non-validator"
  else
    echo "Warning: COMPOSE_FILE is not set or unrecognized. Defaulting to 'non-validator'."
    RUN_MODE="non-validator"
  fi
fi

# Debug: Log the selected RUN_MODE
echo "RUN_MODE: $RUN_MODE"

# Set ROOT_IPS and TRY_NEW_PEERS based on CHAIN
if [ "$CHAIN" = "Mainnet" ]; then
  ROOT_IPS="$MAINNET_ROOT_IPS"
  TRY_NEW_PEERS="$MAINNET_GOSSIP_TRY_NEW_PEERS"
elif [ "$CHAIN" = "Testnet" ]; then
  ROOT_IPS="$TESTNET_ROOT_IPS"
  TRY_NEW_PEERS="$TESTNET_GOSSIP_TRY_NEW_PEERS"
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

# Create override_gossip_config.json
if [ -n "$ROOT_IPS" ] && [ "$ROOT_IPS" != "[]" ]; then
  echo "{ \"root_node_ips\": $ROOT_IPS, \"try_new_peers\": $TRY_NEW_PEERS, \"chain\": \"$CHAIN\" }" > /home/hluser/override_gossip_config.json
  echo "Created /home/hluser/override_gossip_config.json with content: $(cat /home/hluser/override_gossip_config.json)"
else
  echo "Error: No valid root IPs defined for $CHAIN or ROOT_IPS is empty. Cannot proceed."
  exit 1
fi

# Execute the hl-visor command
CMD="/home/hluser/hl-visor run-$RUN_MODE --replica-cmds-style recent-actions"
if [ "$ENABLE_RPC" = "true" ]; then
  CMD="$CMD --serve-eth-rpc"
fi
CMD="$CMD $EXTRA_FLAGS"
echo "Executing: exec $CMD"
exec $CMD
