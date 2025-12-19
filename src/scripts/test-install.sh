#!/bin/bash
#
# Chromix Three - Test Installation
# Checks if all required dependencies are installed
#
# Author: Vanco Ordanoski <vordan@infoproject.biz>
# Company: Infoproject LLC
# License: MIT

echo "Chromix Three - Installation Check"
echo "===================================="
echo ""

ALL_OK=true

# Check Node.js
echo -n "Checking Node.js... "
if command -v node &> /dev/null; then
	NODE_VERSION=$(node --version)
	echo "✓ Installed (${NODE_VERSION})"
else
	echo "✗ Not installed"
	echo "  Install with: sudo apt-get install nodejs"
	ALL_OK=false
fi

# Check npm
echo -n "Checking npm... "
if command -v npm &> /dev/null; then
	NPM_VERSION=$(npm --version)
	echo "✓ Installed (${NPM_VERSION})"
else
	echo "✗ Not installed"
	echo "  Install with: sudo apt-get install npm"
	ALL_OK=false
fi

# Check curl
echo -n "Checking curl... "
if command -v curl &> /dev/null; then
	CURL_VERSION=$(curl --version | head -n1 | cut -d' ' -f2)
	echo "✓ Installed (${CURL_VERSION})"
else
	echo "✗ Not installed"
	echo "  Install with: sudo apt-get install curl"
	ALL_OK=false
fi

echo ""

# Check if server dependencies are installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="${SCRIPT_DIR}/../server"

echo -n "Checking server dependencies... "
if [ -d "${SERVER_DIR}/node_modules" ]; then
	echo "✓ Installed"
else
	echo "✗ Not installed"
	echo "  Run: cd ${SERVER_DIR} && npm install"
	ALL_OK=false
fi

echo ""

# Summary
if [ "$ALL_OK" = true ]; then
	echo "✓ All dependencies are installed!"
	echo ""
	echo "You can now:"
	echo "  - Start server: ./server-start.sh"
	echo "  - Check status: ./server-status.sh"
	echo "  - Reload tabs: ./chromix-three-reload.sh"
else
	echo "✗ Some dependencies are missing."
	echo "Please install them before running Chromix Three."
	exit 1
fi
