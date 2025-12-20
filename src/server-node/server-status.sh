#!/bin/bash
#
# Chromix Three - Server Status
# Checks if server is running and if extension is connected
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

echo "Chromix Three Status"
echo "===================="

# Check if server process is running
if pgrep -f "chromix-three-server.js" > /dev/null; then
	echo "✓ Server process: Running"
	
	# Check if HTTP endpoint is responding
	if curl -s http://localhost:8444/api/status > /dev/null 2>&1; then
		echo "✓ HTTP API: Responding (port 8444)"
		
		# Check if extension is connected
		RESPONSE=$(curl -s http://localhost:8444/api/status)
		CONNECTED=$(echo $RESPONSE | grep -o '"connected":[^,}]*' | cut -d':' -f2)
		
		if [ "$CONNECTED" = "true" ]; then
			echo "✓ Extension: Connected"
			echo ""
			echo "System is ready to use!"
		else
			echo "✗ Extension: Not connected"
			echo ""
			echo "Please load the extension in Chrome:"
			echo "  1. Open chrome://extensions/"
			echo "  2. Enable 'Developer mode'"
			echo "  3. Click 'Load unpacked'"
			echo "  4. Select: chromix-three/extension/"
		fi
	else
		echo "✗ HTTP API: Not responding"
		echo ""
		echo "Server process is running but not responding."
		echo "Try restarting: ./server-stop.sh && ./server-start.sh"
	fi
else
	echo "✗ Server process: Not running"
	echo ""
	echo "Start the server with: ./server-start.sh"
fi
