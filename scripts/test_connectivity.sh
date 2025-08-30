#!/bin/bash

FIREWALL_IPS='[
{"ip": "192.168.1.100", "name": "Test Node 1"},
{"ip": "192.168.1.101", "name": "Test Node 2"},
{"ip": "192.168.1.102", "name": "Test Node 3"},
{"ip": "10.0.0.50", "name": "Mock Validator"},
{"ip": "172.16.0.10", "name": "Example RPC"}
]'

# Loop through IPs
echo "$FIREWALL_IPS" | jq -c '.[]' | while read -r entry; do
    ip=$(echo "$entry" | jq -r '.ip')
    name=$(echo "$entry" | jq -r '.name')
    echo -e "\n=== Testing $name ($ip) ==="
    for port in $(seq 4001 4004); do
        if nc -z -w2 $ip $port 2>/dev/null; then
            echo "Port $port: OPEN"
        else
            echo "Port $port: CLOSED"
        fi
    done
done
