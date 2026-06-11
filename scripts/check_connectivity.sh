#!/bin/bash

set -uo pipefail

PORT_START="${PORT_START:-4001}"
PORT_END="${PORT_END:-4010}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-1}"
MAX_JOBS="${MAX_JOBS:-64}"

if [ -f ".env" ]; then
    ENV_FILE=".env"
elif [ -f "default.env" ]; then
    ENV_FILE="default.env"
else
    echo "Error: No .env or default.env file found"
    exit 1
fi

# Keep compatibility with the existing env files while keeping noisy lines out of
# the connectivity report.
# shellcheck disable=SC1090
source "$ENV_FILE" >/dev/null 2>&1 || true

ROOT_IPS="${MAINNET_ROOT_IPS:-}"
FIREWALL_JSON="${FIREWALL_IPS:-[]}"

if [ -z "$ROOT_IPS" ]; then
    echo "Error: MAINNET_ROOT_IPS not set in $ENV_FILE"
    exit 1
fi

if ! printf '%s\n' "$ROOT_IPS" | jq empty >/dev/null 2>&1; then
    echo "Error: MAINNET_ROOT_IPS is not valid JSON"
    exit 1
fi

if ! printf '%s\n' "$FIREWALL_JSON" | jq empty >/dev/null 2>&1; then
    FIREWALL_JSON="[]"
fi

TMP_DIR="$(mktemp -d)"
ENTRY_FILE="$TMP_DIR/targets.tsv"
RESULTS_FILE="$TMP_DIR/results.tsv"
NO_OPEN_FILE="$TMP_DIR/no-open.txt"
PARTIAL_FILE="$TMP_DIR/partial.txt"
FULL_OPEN_FILE="$TMP_DIR/full-open.txt"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

printf '%s\n' "$ROOT_IPS" | jq -r --argjson firewall "$FIREWALL_JSON" '
    .[] |
    (.Ip // .ip) as $ip |
    select($ip != null) |
    [
        $ip,
        ([ $firewall[]? | select((.ip // .Ip) == $ip) | .name ][0] // "UNKNOWN")
    ] |
    @tsv
' > "$ENTRY_FILE"

TARGET_COUNT="$(wc -l < "$ENTRY_FILE" | tr -d ' ')"
PORT_COUNT="$((PORT_END - PORT_START + 1))"
TOTAL_CHECKS="$((TARGET_COUNT * PORT_COUNT))"
SECONDS=0

probe_port() {
    local ip="$1"
    local port="$2"
    local status="CLOSED"

    if nc -z -w "$TIMEOUT_SECONDS" "$ip" "$port" 2>/dev/null; then
        status="OPEN"
    fi

    printf '%s\t%s\t%s\n' "$ip" "$port" "$status" > "$TMP_DIR/${ip}_${port}.result"
}

running_jobs() {
    jobs -rp | wc -l | tr -d ' '
}

echo "Connectivity check"
echo "Targets: $TARGET_COUNT | Ports: $PORT_START-$PORT_END | Checks: $TOTAL_CHECKS | Timeout: ${TIMEOUT_SECONDS}s | Parallel jobs: $MAX_JOBS"

while IFS=$'\t' read -r ip name; do
    port="$PORT_START"
    while [ "$port" -le "$PORT_END" ]; do
        while [ "$(running_jobs)" -ge "$MAX_JOBS" ]; do
            sleep 0.05
        done

        probe_port "$ip" "$port" &
        port="$((port + 1))"
    done
done < "$ENTRY_FILE"

wait

cat "$TMP_DIR"/*.result > "$RESULTS_FILE"

ports_for() {
    local ip="$1"
    local status="$2"

    awk -F '\t' -v ip="$ip" -v status="$status" '$1 == ip && $3 == status { print $2 }' "$RESULTS_FILE" |
        sort -n |
        paste -sd, -
}

: > "$NO_OPEN_FILE"
: > "$PARTIAL_FILE"
: > "$FULL_OPEN_FILE"

printf '\nDetailed results\n'
printf '%-15s  %-38s  %-23s  %s\n' "IP" "Name" "Open ports" "Closed ports"
printf '%-15s  %-38s  %-23s  %s\n' "---------------" "--------------------------------------" "-----------------------" "-----------------------"

while IFS=$'\t' read -r ip name; do
    open_ports="$(ports_for "$ip" "OPEN")"
    closed_ports="$(ports_for "$ip" "CLOSED")"

    [ -n "$open_ports" ] || open_ports="-"
    [ -n "$closed_ports" ] || closed_ports="-"

    printf '%-15s  %-38s  %-23s  %s\n' "$ip" "$name" "$open_ports" "$closed_ports"

    if [ "$open_ports" = "-" ]; then
        printf '%s (%s)\n' "$name" "$ip" >> "$NO_OPEN_FILE"
    elif [ "$closed_ports" = "-" ]; then
        printf '%s (%s): open=%s\n' "$name" "$ip" "$open_ports" >> "$FULL_OPEN_FILE"
    else
        printf '%s (%s): open=%s closed=%s\n' "$name" "$ip" "$open_ports" "$closed_ports" >> "$PARTIAL_FILE"
    fi
done < "$ENTRY_FILE"

print_summary_section() {
    local title="$1"
    local file="$2"
    local count

    count="$(wc -l < "$file" | tr -d ' ')"
    printf '\n%s (%s)\n' "$title" "$count"
    if [ "$count" -eq 0 ]; then
        echo "  none"
    else
        sed 's/^/  - /' "$file"
    fi
}

printf '\nSummary\n'
echo "Completed in ${SECONDS}s"
print_summary_section "No open ports (likely not whitelisted or unreachable)" "$NO_OPEN_FILE"
print_summary_section "Partially reachable" "$PARTIAL_FILE"
print_summary_section "All tested ports open" "$FULL_OPEN_FILE"
