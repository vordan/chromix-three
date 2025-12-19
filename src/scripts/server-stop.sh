#!/bin/bash
#
# Chromix Three - Stop Server
# Stops the chromix-three server
#
# Author: Vanco Ordanoski <vordan@infoproject.biz>
# Company: Infoproject LLC
# License: MIT

# Find and kill the server process
if pgrep -f "chromix-three-server.js" > /dev/null; then
	echo "Stopping chromix-three server..."
	pkill -f "chromix-three-server.js"
	sleep 1
	
	# Check if stopped
	if pgrep -f "chromix-three-server.js" > /dev/null; then
		echo "✗ Failed to stop server (trying force kill)"
		pkill -9 -f "chromix-three-server.js"
		sleep 1
	fi
	
	if pgrep -f "chromix-three-server.js" > /dev/null; then
		echo "✗ Failed to stop server"
		exit 1
	else
		echo "✓ Server stopped"
	fi
else
	echo "Server is not running"
fi
