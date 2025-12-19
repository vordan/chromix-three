#!/bin/bash
#
# Chromix Three - Installation Script
# Installs server and deactivates chromix-too if running
#
# Author: Vanco Ordanoski <vordan@infoproject.biz>
# Company: Infoproject LLC
# License: MIT

echo "Chromix Three - Installation"
echo "============================="
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
	echo "Error: Node.js is not installed"
	echo "Install it with: sudo apt-get install nodejs"
	exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
	echo "Error: npm is not installed"
	echo "Install it with: sudo apt-get install npm"
	exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
	echo "Error: curl is not installed"
	echo "Install it with: sudo apt-get install curl"
	exit 1
fi

echo "✓ All required dependencies found"
echo ""

# Deactivate chromix-too server if running
echo "Checking for chromix-too server..."
if pgrep -f "chromix-too-server" > /dev/null; then
	echo "Found chromix-too server running. Stopping it..."
	pkill -f "chromix-too-server"
	sleep 1
	
	if pgrep -f "chromix-too-server" > /dev/null; then
		echo "Warning: Could not stop chromix-too-server"
		echo "Please stop it manually: pkill -f chromix-too-server"
	else
		echo "✓ chromix-too server stopped"
	fi
else
	echo "✓ chromix-too server not running"
fi

echo ""

# Get script directory and server directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="${SCRIPT_DIR}/../server"

# Install server dependencies
echo "Installing server dependencies..."
cd "${SERVER_DIR}"

if npm install; then
	echo "✓ Server dependencies installed"
else
	echo "✗ Failed to install dependencies"
	exit 1
fi

echo ""
echo "============================="
echo "Installation Complete!"
echo "============================="
echo ""
echo "Next steps:"
echo ""
echo "1. Start the server:"
echo "   cd scripts"
echo "   ./server-start.sh"
echo ""
echo "2. Load the Chrome extension:"
echo "   - Open chrome://extensions/"
echo "   - Enable 'Developer mode'"
echo "   - Click 'Load unpacked'"
echo "   - Select: chromix-three/extension/"
echo ""
echo "3. Test the installation:"
echo "   ./server-status.sh"
echo ""
echo "4. Use in development:"
echo "   ./chromix-three-reload.sh"
echo ""
