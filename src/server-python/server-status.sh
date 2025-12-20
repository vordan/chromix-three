#!/bin/bash
#
# Chromix Three - Python Server Status
# Checks if server and extension are running and connected
#
# Author: Vanco Ordanoski <vordan@infoproject.biz>
# Company: Infoproject LLC
# License: MIT

echo "Chromix Three Python Server Status"
echo "==================================="
echo ""

# Check if curl is installed
if ! command -v curl &> /dev/null; then
	echo "Error: curl is not installed"
	echo "Install it with: sudo apt-get install curl"
	exit 1
fi

# Check if server process is running
PID=$(pgrep -f "chromix-three-server.py")
if [ -n "$PID" ]; then
	echo "✓ Server process: Running (PID: $PID)"
else
	echo "✗ Server process: Not running"
	echo ""
	echo "Start the server with:"
	echo "  ./server-start.sh"
	exit 1
fi

# Check if HTTP API is responding
if curl -s -f http://localhost:8444/api/status > /dev/null 2>&1; then
	echo "✓ HTTP API: Responding"
else
	echo "✗ HTTP API: Not responding"
	echo ""
	echo "Try restarting the server:"
	echo "  ./server-stop.sh && ./server-start.sh"
	exit 1
fi

# Check if extension is connected
RESPONSE=$(curl -s http://localhost:8444/api/status)
CONNECTED=$(echo "$RESPONSE" | grep -o '"connected":[^,}]*' | cut -d':' -f2)

if [ "$CONNECTED" = "true" ]; then
	echo "✓ Extension: Connected"
	echo ""
	echo "Everything is working! You can reload tabs with:"
	echo "  ../../scripts/chromix-three-reload.sh"
else
	echo "✗ Extension: Not connected"
	echo ""
	echo "Make sure the Chrome extension is installed and enabled:"
	echo "1. Open chrome://extensions/"
	echo "2. Enable 'Developer mode'"
	echo "3. Check that 'Chromix Three' is enabled"
	echo "4. Click the extension's 'Reload' button if needed"
	exit 1
fi
