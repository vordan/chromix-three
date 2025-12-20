#!/bin/bash
#
# Chromix Three - Start Python Server
# Starts the chromix-three Python server in the background
#
# Author: Vanco Ordanoski <vordan@infoproject.biz>
# Company: Infoproject LLC
# License: MIT

# Check if python3 is installed
if ! command -v python3 &> /dev/null; then
	echo "Error: Python 3 is not installed"
	echo "Install it with: sudo apt-get install python3"
	exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
	echo "Error: curl is not installed"
	echo "Install it with: sudo apt-get install curl"
	exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_FILE="${SCRIPT_DIR}/chromix-three-server.py"

# Check if server file exists
if [ ! -f "${SERVER_FILE}" ]; then
	echo "Error: Server file not found at ${SERVER_FILE}"
	exit 1
fi

# Check if server is already running
if pgrep -f "chromix-three-server.py" > /dev/null; then
	echo "✓ Server is already running"
	exit 0
fi

# Check if required Python packages are installed
if ! python3 -c "import websockets, aiohttp" 2>/dev/null; then
	echo "Error: Required Python packages not installed"
	echo ""
	echo "Install with:"
	echo "  pip3 install websockets aiohttp"
	echo ""
	exit 1
fi

# Start server in background
echo "Starting chromix-three Python server..."
cd "${SCRIPT_DIR}"
nohup python3 chromix-three-server.py > /dev/null 2>&1 &

# Wait a moment for server to start
sleep 2

# Check if it started successfully
if pgrep -f "chromix-three-server.py" > /dev/null; then
	echo "✓ Server started successfully"
	echo "  HTTP API: http://localhost:8444"
	echo "  WebSocket: ws://localhost:7444"
else
	echo "✗ Failed to start server"
	exit 1
fi
