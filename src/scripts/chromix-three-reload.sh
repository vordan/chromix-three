#!/bin/bash
#
# Chromix Three - Reload Development Server Tabs
# Reloads the first tab matching 10.10.*.* pattern
#
# Author: Vanco Ordanoski <vordan@infoproject.biz>
# Company: Infoproject LLC
# License: MIT

# Check if curl is installed
if ! command -v curl &> /dev/null; then
	echo "Error: curl is not installed"
	echo "Install it with: sudo apt-get install curl"
	exit 1
fi

# URL pattern to match (dev server on local network)
URL_PATTERN="10.10.*.*"

# Send reload command to chromix-three server
curl -s -X POST http://localhost:8444/api/command \
	-H "Content-Type: application/json" \
	-d "{\"command\":\"reload\",\"url\":\"${URL_PATTERN}\"}" > /dev/null

# Check if command was successful
if [ $? -eq 0 ]; then
	echo "✓ Reloaded tabs matching: ${URL_PATTERN}"
else
	echo "✗ Failed to reload tabs. Is the server running?"
	exit 1
fi
