#!/bin/bash

# Measure network latency to the MAINNET_ROOT_IPS peers using a TCP connect to an
# open p2p port, rather than ICMP ping. Cloud hosts (AWS) typically drop ICMP echo
# while allowing the gossip ports, so `ping` reports them unreachable even though
# the node gossips with them fine. Timing the TCP handshake gives a real,
# comparable RTT over the path that actually matters, with no root and no extra deps.
#
# Reports name, IP, avg/min/max connect RTT (ms) and success count per host.
#
# Tunables (env): PORT (default 4001), COUNT (default 5), TIMEOUT seconds (default 2)

set -uo pipefail

PORT="${PORT:-4001}"        # an open p2p port (see scripts/check_connectivity.sh)
COUNT="${COUNT:-5}"         # connects per host
TIMEOUT="${TIMEOUT:-2}"     # per-connect timeout (seconds)

if [ -f ".env" ]; then
    ENV_FILE=".env"
elif [ -f "default.env" ]; then
    ENV_FILE="default.env"
else
    echo "Error: No .env or default.env file found"
    exit 1
fi

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
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Same parsing/name-lookup as scripts/check_connectivity.sh
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

echo "TCP-connect latency to port $PORT (MAINNET_ROOT_IPS)"
echo "Targets: $TARGET_COUNT | Connects each: $COUNT | Timeout: ${TIMEOUT}s"

python3 - "$ENTRY_FILE" "$PORT" "$COUNT" "$TIMEOUT" <<'PY'
import socket, time, sys
entry_file, port, count, timeout = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), float(sys.argv[4])
print(f'\n{"Name":38}  {"IP":15}  {"avg ms":>8}  {"min":>7}  {"max":>7}  {"ok":>6}')
print(f'{"-"*38}  {"-"*15}  {"-"*8}  {"-"*7}  {"-"*7}  {"-"*6}')
for line in open(entry_file):
    if not line.strip():
        continue
    ip, name = (line.rstrip("\n").split("\t") + ["UNKNOWN"])[:2]
    ts = []
    for _ in range(count):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        t0 = time.perf_counter()
        try:
            s.connect((ip, port))
            ts.append((time.perf_counter() - t0) * 1000)
        except Exception:
            pass
        finally:
            s.close()
        time.sleep(0.1)  # be gentle - avoid hammering peers with rapid handshakes
    if ts:
        ts.sort()
        avg = sum(ts) / len(ts)
        print(f'{name:38.38}  {ip:15}  {avg:8.2f}  {ts[0]:7.2f}  {ts[-1]:7.2f}  {len(ts)}/{count:<4}')
    else:
        print(f'{name:38.38}  {ip:15}  {"-":>8}  {"-":>7}  {"-":>7}  0/{count:<4}')
PY
