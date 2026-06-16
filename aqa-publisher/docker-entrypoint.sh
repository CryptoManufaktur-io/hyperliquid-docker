#!/usr/bin/env bash
set -euo pipefail

if [ -n "${AQA_PUBLISHER_PRIVATE_KEY:-}" ]; then
  export PUBLISHER_PRIVATE_KEY="${AQA_PUBLISHER_PRIVATE_KEY}"
fi

export NETWORK="${AQA_PUBLISHER_NETWORK:-${NETWORK:-mainnet}}"
export RUST_LOG="${AQA_PUBLISHER_RUST_LOG:-${RUST_LOG:-info}}"

exec "$@"
