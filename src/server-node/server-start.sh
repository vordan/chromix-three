#!/bin/bash
#
# Chromix Three - Start Server
# Starts the chromix-three server in the background
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

# Check if node is installed
if ! command -v node &> /dev/null; then
	echo "Error: Node.js is not installed"
	echo "Install it with: sudo apt-get install nodejs"
	exit 1
fi

# Get script directory (same as server directory now)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="${SCRIPT_DIR}"
SERVER_FILE="${SERVER_DIR}/chromix-three-server.js"

# Check if server file exists
if [ ! -f "${SERVER_FILE}" ]; then
	echo "Error: Server file not found at ${SERVER_FILE}"
	exit 1
fi

# Check if server is already running
if pgrep -f "chromix-three-server.js" > /dev/null; then
	echo "✓ Server is already running"
	exit 0
fi

# Start server in background
echo "Starting chromix-three server..."
cd "${SERVER_DIR}"
nohup node chromix-three-server.js > /dev/null 2>&1 &

# Wait a moment for server to start
sleep 2

# Check if it started successfully
if pgrep -f "chromix-three-server.js" > /dev/null; then
		echo "✓ Server started successfully"
		echo "  HTTP API: http://localhost:8444"
		echo "  WebSocket: ws://localhost:7444"
else
	echo "✗ Failed to start server"
	exit 1
fi
