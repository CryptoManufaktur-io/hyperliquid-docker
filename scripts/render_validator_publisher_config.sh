#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${1:-$PROJECT_ROOT/.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' not found" >&2
    exit 1
  fi
}

require_var() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "Error: required variable '$name' is not set" >&2
    exit 1
  fi
}

require_command jq

: "${VALIDATOR_PUBLISHER_CONFIG_PATH:=$PROJECT_ROOT/validator-publisher/config.json}"
: "${VALIDATOR_PUBLISHER_RPC_SEVENTH_NAME:=getblock}"
: "${VALIDATOR_PUBLISHER_ETHERSCAN_API_URL:=https://api.etherscan.io/v2/api}"
: "${VALIDATOR_PUBLISHER_BLOCKSCOUT_URL:=https://arbitrum.blockscout.com/api}"
: "${VALIDATOR_PUBLISHER_CRIT_MSG_IGNORES:=[]}"

case "$VALIDATOR_PUBLISHER_CONFIG_PATH" in
  /*) ;;
  *) VALIDATOR_PUBLISHER_CONFIG_PATH="$PROJECT_ROOT/${VALIDATOR_PUBLISHER_CONFIG_PATH#./}" ;;
esac

required_vars=(
  VALIDATOR_PUBLISHER_AGENT_KEY
  VALIDATOR_PUBLISHER_RPC_ALCHEMY_URL
  VALIDATOR_PUBLISHER_RPC_QUICKNODE_URL
  VALIDATOR_PUBLISHER_RPC_INFURA_URL
  VALIDATOR_PUBLISHER_RPC_CHAINSTACK_URL
  VALIDATOR_PUBLISHER_RPC_ANKR_URL
  VALIDATOR_PUBLISHER_RPC_DRPC_URL
  VALIDATOR_PUBLISHER_RPC_SEVENTH_URL
  VALIDATOR_PUBLISHER_SLACK_KEY
  VALIDATOR_PUBLISHER_SLACK_ERRORS_CHANNEL
  VALIDATOR_PUBLISHER_SLACK_OUTCOME_ACTIONS_CHANNEL
)

for var_name in "${required_vars[@]}"; do
  require_var "$var_name"
done

if ! printf '%s\n' "$VALIDATOR_PUBLISHER_CRIT_MSG_IGNORES" | jq -e 'type == "array"' >/dev/null; then
  echo "Error: VALIDATOR_PUBLISHER_CRIT_MSG_IGNORES must be a JSON array" >&2
  exit 1
fi

rpcs_json="$(
  jq -n \
    --arg alchemy "$VALIDATOR_PUBLISHER_RPC_ALCHEMY_URL" \
    --arg quicknode "$VALIDATOR_PUBLISHER_RPC_QUICKNODE_URL" \
    --arg infura "$VALIDATOR_PUBLISHER_RPC_INFURA_URL" \
    --arg chainstack "$VALIDATOR_PUBLISHER_RPC_CHAINSTACK_URL" \
    --arg ankr "$VALIDATOR_PUBLISHER_RPC_ANKR_URL" \
    --arg drpc "$VALIDATOR_PUBLISHER_RPC_DRPC_URL" \
    --arg seventh_name "$VALIDATOR_PUBLISHER_RPC_SEVENTH_NAME" \
    --arg seventh_url "$VALIDATOR_PUBLISHER_RPC_SEVENTH_URL" \
    '[
      {"name": "alchemy", "url": $alchemy},
      {"name": "quicknode", "url": $quicknode},
      {"name": "infura", "url": $infura},
      {"name": "chainstack", "url": $chainstack},
      {"name": "ankr", "url": $ankr},
      {"name": "drpc", "url": $drpc},
      {"name": $seventh_name, "url": $seventh_url}
    ]'
)"

explorers_json="$(
  jq -n \
    --arg etherscan_url "$VALIDATOR_PUBLISHER_ETHERSCAN_API_URL" \
    --arg etherscan_key "${VALIDATOR_PUBLISHER_ETHERSCAN_API_KEY:-}" \
    --arg blockscout_url "$VALIDATOR_PUBLISHER_BLOCKSCOUT_URL" \
    '[
      if ($etherscan_key | length) > 0 then
        {"name": "etherscan", "url": $etherscan_url, "api_key": $etherscan_key}
      else empty end,
      if ($blockscout_url | length) > 0 then
        {"name": "blockscout", "url": $blockscout_url}
      else empty end
    ]'
)"

if [ "$(printf '%s\n' "$explorers_json" | jq 'length')" -lt 1 ]; then
  echo "Error: configure at least one explorer endpoint" >&2
  exit 1
fi

mkdir -p "$(dirname "$VALIDATOR_PUBLISHER_CONFIG_PATH")"
tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

jq -n \
  --arg agent_key "$VALIDATOR_PUBLISHER_AGENT_KEY" \
  --argjson rpcs "$rpcs_json" \
  --argjson explorers "$explorers_json" \
  --arg slack_key "$VALIDATOR_PUBLISHER_SLACK_KEY" \
  --arg errors_channel "$VALIDATOR_PUBLISHER_SLACK_ERRORS_CHANNEL" \
  --arg outcome_actions_channel "$VALIDATOR_PUBLISHER_SLACK_OUTCOME_ACTIONS_CHANNEL" \
  --argjson crit_msg_ignores "$VALIDATOR_PUBLISHER_CRIT_MSG_IGNORES" \
  '{
    agent_key: $agent_key,
    bridge_voter: {
      rpcs: $rpcs,
      explorers: $explorers
    },
    reference_oracle_publisher: {},
    slack: {
      api_key: $slack_key,
      errors_channel: $errors_channel,
      outcome_actions_channel: $outcome_actions_channel,
      crit_msg_ignores: $crit_msg_ignores
    }
  }' > "$tmp_file"

mv "$tmp_file" "$VALIDATOR_PUBLISHER_CONFIG_PATH"
chmod 0600 "$VALIDATOR_PUBLISHER_CONFIG_PATH"
echo "Wrote validator-publisher config to $VALIDATOR_PUBLISHER_CONFIG_PATH"
