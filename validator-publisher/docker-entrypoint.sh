#!/usr/bin/env bash
set -euo pipefail

: "${VALIDATOR_PUBLISHER_CONFIG_PATH:=/opt/validator-publisher/config/config.json}"
: "${VALIDATOR_PUBLISHER_FORWARD_FILE_LOGS:=true}"
: "${VALIDATOR_PUBLISHER_FORWARD_LOG_TAIL_LINES:=20}"
: "${VALIDATOR_PUBLISHER_LOG_DISCOVERY_INTERVAL:=1}"
export VALIDATOR_PUBLISHER_CONFIG_PATH

is_truthy() {
  case "${1,,}" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

log_dir_from_args() {
  local log_dir="/opt/validator-publisher/logs"
  local -a args=("$@")

  for ((i = 0; i < ${#args[@]}; i++)); do
    if [[ "${args[$i]}" == "--log-dir" && $((i + 1)) -lt ${#args[@]} ]]; then
      log_dir="${args[$((i + 1))]}"
      break
    fi
  done

  printf '%s\n' "$log_dir"
}

forward_component_logs() {
  local log_dir="$1"
  local tail_lines="$2"
  local interval="$3"
  local -a forwarder_pids=()
  local -A forwarded=()

  if ! [[ "$tail_lines" =~ ^[0-9]+$ ]]; then
    tail_lines=20
  fi

  if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
    interval=1
  fi

  # shellcheck disable=SC2317,SC2329
  cleanup_forwarders() {
    if [[ ${#forwarder_pids[@]} -gt 0 ]]; then
      kill "${forwarder_pids[@]}" 2>/dev/null || true
    fi
  }

  trap 'cleanup_forwarders; exit 0' TERM INT EXIT

  while true; do
    local today
    today="$(date -u +%Y%m%d)"

    if [[ -d "$log_dir" ]]; then
      while IFS= read -r -d '' log_file; do
        if [[ -n "${forwarded[$log_file]:-}" ]]; then
          continue
        fi

        local component
        component="$(basename "$(dirname "$log_file")")"
        (
          tail -n "$tail_lines" -F "$log_file" 2>/dev/null | while IFS= read -r line; do
            printf '[validator-publisher:%s] %s\n' "$component" "$line"
          done
        ) &
        forwarder_pids+=("$!")
        forwarded["$log_file"]=1
      done < <(find "$log_dir" -mindepth 2 -maxdepth 2 -type f -name "$today" -print0 2>/dev/null)
    fi

    sleep "$interval" &
    wait "$!" || true
  done
}

render_validator_publisher_config.sh /dev/null

if ! is_truthy "$VALIDATOR_PUBLISHER_FORWARD_FILE_LOGS"; then
  exec /opt/validator-publisher/bin/validator-publisher-visor "$@"
fi

log_dir="$(log_dir_from_args "$@")"
forward_component_logs "$log_dir" "$VALIDATOR_PUBLISHER_FORWARD_LOG_TAIL_LINES" "$VALIDATOR_PUBLISHER_LOG_DISCOVERY_INTERVAL" &
log_forwarder_pid="$!"

/opt/validator-publisher/bin/validator-publisher-visor "$@" &
visor_pid="$!"

# shellcheck disable=SC2317,SC2329
terminate() {
  trap - TERM INT
  kill "$visor_pid" "$log_forwarder_pid" 2>/dev/null || true
  wait "$visor_pid" 2>/dev/null || true
  wait "$log_forwarder_pid" 2>/dev/null || true
}

trap terminate TERM INT

if wait "$visor_pid"; then
  visor_status=0
else
  visor_status="$?"
fi

kill "$log_forwarder_pid" 2>/dev/null || true
wait "$log_forwarder_pid" 2>/dev/null || true

exit "$visor_status"
