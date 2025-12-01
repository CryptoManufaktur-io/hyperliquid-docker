#!/usr/bin/env bash
# Query the active validator set for Hyperliquid
# Displays all validators where isActive == true, sorted by stake
#
# Usage: ./check_active_set.sh [mainnet|testnet]
#   If no argument is provided, uses CHAIN from .env or default.env

# Get the script directory and the project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check for command-line argument first
if [ -n "$1" ]; then
    case "${1,,}" in  # Convert to lowercase
        mainnet)
            CHAIN="Mainnet"
            ;;
        testnet)
            CHAIN="Testnet"
            ;;
        *)
            echo "Usage: $0 [mainnet|testnet]"
            echo "  If no argument is provided, uses CHAIN from .env or default.env"
            exit 1
            ;;
    esac
else
    # ——————— Load .env and export everything ———————
    set -o allexport
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env"
    elif [ -f "$PROJECT_ROOT/default.env" ]; then
        source "$PROJECT_ROOT/default.env"
    else
        echo "Error: No environment file found"
        exit 1
    fi
    set +o allexport

    # Check if CHAIN variable is set
    if [ -z "${CHAIN+x}" ]; then
        echo "Error: CHAIN variable is not set in the environment file"
        exit 1
    fi
fi

# ——————— Define API endpoints ———————
case "${CHAIN}" in
    Testnet)
        API_URL="https://api.hyperliquid-testnet.xyz/info"
        ;;
    Mainnet)
        API_URL="https://api.hyperliquid.xyz/info"
        ;;
    *)
        echo "❌ Invalid CHAIN value: '$CHAIN'. Must be 'Testnet' or 'Mainnet'."
        exit 1
        ;;
esac

echo "=========================================="
echo "Hyperliquid Active Validator Set"
echo "=========================================="
echo "Network: $CHAIN"
echo "API Endpoint: $API_URL"
echo "=========================================="
echo ""

# ——————— Query validator summaries ———————
RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d '{"type":"validatorSummaries"}')

# Check if curl succeeded
if [ -z "$RESPONSE" ]; then
    echo "❌ Failed to fetch validator data from API"
    exit 1
fi

# Check for API errors
if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo "❌ API Error: $(echo "$RESPONSE" | jq -r '.error')"
    exit 1
fi

# ——————— Process and display active validators ———————
echo "Active Validators (sorted by stake):"
echo ""

# Filter active validators, sort by stake, and format output
echo "$RESPONSE" | jq -r '
    map(select(.isActive == true))
    | sort_by(-.stake)
    | to_entries
    | .[]
    | "\(.key + 1)\t\(.value.stake)\t\(.value.name)\t\(.value.validator)"
' | while IFS=$'\t' read -r rank stake name validator; do
    # Convert from dust (8 decimals) to HYPE and format with commas
    formatted_stake=$(echo "$stake" | awk '{printf "%'\''0.2f", $1 / 100000000}')
    printf "%3s. %-35s %18s HYPE  %s\n" "$rank" "$name" "$formatted_stake" "$validator"
done

echo ""
echo "=========================================="

# ——————— Summary statistics ———————
TOTAL_ACTIVE=$(echo "$RESPONSE" | jq '[.[] | select(.isActive == true)] | length')
TOTAL_STAKE=$(echo "$RESPONSE" | jq '[.[] | select(.isActive == true)] | map(.stake | tonumber) | add')
FORMATTED_TOTAL=$(echo "$TOTAL_STAKE" | awk '{printf "%'\''0.2f", $1 / 100000000}')

echo "Total Active Validators: $TOTAL_ACTIVE"
echo "Total Staked: $FORMATTED_TOTAL HYPE"
echo "=========================================="
