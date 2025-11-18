#!/bin/bash

# Load environment variables from .env file
if [ -f ".env" ]; then
    source .env
elif [ -f "default.env" ]; then
    source default.env
else
    echo "Error: No .env or default.env file found"
    exit 1
fi

# Use MAINNET_ROOT_IPS from .env file
ROOT_IPS="${MAINNET_ROOT_IPS}"

if [ -z "$ROOT_IPS" ]; then
    echo "Error: MAINNET_ROOT_IPS not set in .env file"
    exit 1
fi

# Loop through IPs
echo "$ROOT_IPS" | jq -c '.[]' | while read -r entry; do
    ip=$(echo "$entry" | jq -r '.Ip')
    echo -e "\n=== Testing Root IP ($ip) ==="
    for port in $(seq 4001 4010); do
        if nc -z -w2 "$ip" "$port" 2>/dev/null; then
            echo "Port $port: OPEN"
        else
            echo "Port $port: CLOSED"
        fi
    done
done
