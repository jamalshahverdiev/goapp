#!/bin/bash

# Check availability sh script
GO_URL="${1:-"127.0.0.1:8080"}"

response=$(curl -X GET -s -o /dev/null -w "%{http_code}" "$GO_URL")
if [ $response -eq 200 ]; then
    echo "Available"
else
    echo "Unavailable"
    exit 1
fi