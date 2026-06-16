#!/usr/bin/env bash
set -euo pipefail

: "${VALIDATOR_PUBLISHER_CONFIG_PATH:=/opt/validator-publisher/config/config.json}"
export VALIDATOR_PUBLISHER_CONFIG_PATH

render_validator_publisher_config.sh /dev/null
exec validator-publisher-visor "$@"
