#!/bin/bash
#
# Chromix Three - Stop Python Server
# Stops the chromix-three Python server
#
# Author: Vanco Ordanoski <vordan@infoproject.biz>
# Company: Infoproject LLC
# License: MIT

# Find the server process
PID=$(pgrep -f "chromix-three-server.py")

if [ -z "$PID" ]; then
	echo "✓ Server is not running"
	exit 0
fi

# Try graceful shutdown first
echo "Stopping chromix-three Python server (PID: $PID)..."
kill $PID

# Wait a moment
sleep 2

# Check if it stopped
if ! pgrep -f "chromix-three-server.py" > /dev/null; then
	echo "✓ Server stopped successfully"
	exit 0
fi

# If still running, force kill
echo "Server still running, forcing shutdown..."
kill -9 $PID

sleep 1

# Final check
if ! pgrep -f "chromix-three-server.py" > /dev/null; then
	echo "✓ Server stopped successfully"
else
	echo "✗ Failed to stop server"
	exit 1
fi
