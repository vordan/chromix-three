# Chromix Three

Developer tool for controlling Chrome browser from the command line.

Version: 1.2.0  
Date: December 20, 2025
Author: Vanco Ordanoski <vordan@infoproject.biz>
Company: Infoproject LLC
License: MIT

## Credits

This project is inspired by and based on the original [chromix-too](https://github.com/smblott-github/chromix-too) by Stephen Blott. Thank you to the original authors for their excellent work. Chromix Three is a modern reimplementation with Manifest v3 support, simplified architecture, and additional features.

## Overview

Chromix Three allows developers to control Chrome tabs from command-line scripts or editor shortcuts. The primary use case is reloading development server tabs instantly while coding, without switching windows or using the mouse.

The system consists of three components:

1. **Local server** (HTTP + WebSocket) - Available in two implementations:
   - Node.js version (default)
   - Python version (alternative, no Node.js required)
2. **Chrome extension** (Manifest v3 service worker)
3. **Helper scripts** for common operations

## Architecture

```
Command line / Editor
        |
        | (HTTP POST)
        v
    Local Server (localhost:8444, localhost:7444)
    [Node.js OR Python implementation]
        |
        | (WebSocket)
        v
    Chrome Extension
        |
        | (Chrome API)
        v
    Browser Tabs
```

The extension maintains a WebSocket connection to the local server. Commands sent via HTTP are forwarded to the extension, which executes the corresponding Chrome API calls and returns results.

**Both server implementations use identical protocols** - the Chrome extension works with either one without any changes.

## Requirements

**Core requirements:**
- curl
- Chrome browser

**Server requirements (choose one):**

**Option A: Node.js Server (default)**
- Node.js >= 14.0.0
- npm

**Option B: Python Server (alternative)**
- Python 3.7+
- pip3
- Packages: `websockets`, `aiohttp`

## Installation

You can choose between Node.js or Python server. **Both work identically** - pick whichever you prefer.

### Option A: Node.js Server (Default)

**1. Install Server**

```bash
cd chromix-three/src/server-node
./install.sh
```

The install script will:
- Check dependencies (Node.js, npm, curl)
- Stop chromix-too server if running (does not delete it)
- Install server packages
- Display next steps

**2. Start Server**

```bash
./server-start.sh
```

The server runs in the background on:
- HTTP API: localhost:8444
- WebSocket: localhost:7444

### Option B: Python Server (Alternative)

**1. Install Dependencies**

```bash
cd chromix-three/src/server-python
pip3 install websockets aiohttp
```

**2. Start Server**

```bash
./server-start.sh
```

Or run directly:
```bash
python3 chromix-three-server.py
```

The server runs in the background on:
- HTTP API: localhost:8444
- WebSocket: localhost:7444

See `src/server-python/README.md` for detailed Python server documentation.

### Install Chrome Extension (Required for Both Servers)

**Option A: Load Unpacked**

1. Open `chrome://extensions/`
2. Enable "Developer mode" (toggle in top-right)
3. Click "Load unpacked"
4. Select `chromix-three/src/extension/` folder

**Option B: Install CRX File**

1. Download the .crx file
2. Open `chrome://extensions/`
3. Drag and drop the .crx file onto the page

### Verify Installation

**For Node.js server:**
```bash
cd chromix-three/src/server-node
./server-status.sh
```

**For Python server:**
```bash
cd chromix-three/src/server-python
./server-status.sh
```

Both should show:
- Server process: Running
- HTTP API: Responding
- Extension: Connected

## Usage

### Reload Development Server Tabs

Main use case - reload tabs matching a URL pattern:

```bash
./chromix-three-reload.sh
```

Default pattern: `10.10.*.*` (matches VPN network development servers, but do use your own)

### Manual Commands

All commands use HTTP POST to `localhost:8444/api/command`

**Reload tabs:**
```bash
curl -X POST http://localhost:8444/api/command \
  -H "Content-Type: application/json" \
  -d '{"command":"reload","url":"10.10.*.*"}'
```

**Reload all matching tabs:**
```bash
curl -X POST http://localhost:8444/api/command \
  -H "Content-Type: application/json" \
  -d '{"command":"reload","url":"10.10.*.*","scope":"all"}'
```

**List tabs:**
```bash
curl -X POST http://localhost:8444/api/command \
  -H "Content-Type: application/json" \
  -d '{"command":"list"}'
```

**List tabs by pattern:**
```bash
curl -X POST http://localhost:8444/api/command \
  -H "Content-Type: application/json" \
  -d '{"command":"list","url":"localhost"}'
```

**Close tabs:**
```bash
curl -X POST http://localhost:8444/api/command \
  -H "Content-Type: application/json" \
  -d '{"command":"close","url":"example.com"}'
```

**Open new tab:**
```bash
curl -X POST http://localhost:8444/api/command \
  -H "Content-Type: application/json" \
  -d '{"command":"open","url":"https://google.com"}'
```

**Check status:**
```bash
curl http://localhost:8444/api/status
```

### URL Pattern Matching

Patterns support wildcards using `*`:

- `10.10.*.*` - Matches any IP starting with 10.10
- `localhost:*` - Matches localhost on any port
- `*.example.com` - Matches any subdomain of example.com
- `http://10.*` - Matches any URL starting with http://10

Without wildcards, simple substring matching is used.

### Scope Parameter

The `reload` command accepts a `scope` parameter:

- `scope: "first"` (default) - Reloads only the first matching tab
- `scope: "all"` - Reloads all matching tabs

Example:
```bash
curl -X POST http://localhost:8444/api/command \
  -H "Content-Type: application/json" \
  -d '{"command":"reload","url":"localhost","scope":"all"}'
```

## Editor Integration

### Geany

1. Go to Edit > Preferences > Tools > Custom Commands
2. Add new command:
   ```
   /path/to/chromix-three/src/scripts/chromix-three-reload.sh
   ```
3. Bind to keyboard shortcut (e.g., Ctrl+F1, I use it because it's convenient)

### Other Editors

Most editors support executing shell commands. Add the reload script path and bind to a convenient shortcut.

## Helper Scripts

**Node.js server scripts** (in `src/server-node/`):
- `install.sh` - Install Node.js server and dependencies
- `server-start.sh` - Start Node.js server in background
- `server-stop.sh` - Stop Node.js server
- `server-status.sh` - Check Node.js server and extension status
- `test-install.sh` - Verify all dependencies are installed

**Python server scripts** (in `src/server-python/`):
- `server-start.sh` - Start Python server in background
- `server-stop.sh` - Stop Python server
- `server-status.sh` - Check Python server and extension status

**Shared scripts** (in `src/scripts/`):
- `chromix-three-reload.sh` - Reload dev server tabs (works with both servers)

See `src/server-node/README.md`, `src/server-python/README.md`, and `src/scripts/README.md` for detailed documentation.

## Project Structure

```
chromix-three/
├── src/
│   ├── server-node/                   # Node.js server (default)
│   │   ├── chromix-three-server.js    # Main Node.js server
│   │   ├── websocket.js               # WebSocket handler
│   │   ├── package.json
│   │   ├── package-lock.json
│   │   ├── install.sh                 # Install Node.js dependencies
│   │   ├── server-start.sh            # Start Node.js server
│   │   ├── server-stop.sh             # Stop Node.js server
│   │   ├── server-status.sh           # Check Node.js server status
│   │   └── test-install.sh            # Test Node.js installation
│   ├── server-python/                 # Python server (alternative)
│   │   ├── chromix-three-server.py    # Main Python server
│   │   ├── server-start.sh            # Start Python server
│   │   ├── server-stop.sh             # Stop Python server
│   │   ├── server-status.sh           # Check Python server status
│   │   └── README.md                  # Python server docs
│   ├── extension/                     # Chrome extension
│   │   ├── manifest.json              # Manifest v3
│   │   ├── service-worker.js          # Background service worker
│   │   ├── popup.html                 # Extension info popup
│   │   └── icons/                     # Extension icons
│   │       ├── icon-16.png
│   │       ├── icon-32.png
│   │       ├── icon-48.png
│   │       └── chromix-three.128.png
│   ├── scripts/                       # Shared scripts
│   │   ├── chromix-three-reload.sh    # Reload tabs (works with both servers)
│   │   └── README.md
│   ├── chromix-three.service          # Systemd service file (Node.js)
│   ├── chromix-three.crx              # Packaged extension (not in git)
│   └── chromix-three.pem              # Extension key (not in git)
├── LICENSE
└── README.md
```

## Server Management

### Node.js Server

**Start server:**
```bash
cd chromix-three/src/server-node
./server-start.sh
```

**Stop server:**
```bash
./server-stop.sh
```

**Check status:**
```bash
./server-status.sh
```

**Restart server:**
```bash
./server-stop.sh && ./server-start.sh
```

### Python Server

**Start server:**
```bash
cd chromix-three/src/server-python
./server-start.sh
```

**Stop server:**
```bash
./server-stop.sh
```

**Check status:**
```bash
./server-status.sh
```

**Restart server:**
```bash
./server-stop.sh && ./server-start.sh
```

### Auto-start on Boot

The server does NOT automatically start on system reboot. You must start it manually or configure it to autostart.

#### Option 1: Systemd Service (Recommended)

**For Node.js server:**

A systemd service file is provided at `src/chromix-three.service`. Edit it to match your paths:

```bash
sudo cp src/chromix-three.service /etc/systemd/system/
sudo nano /etc/systemd/system/chromix-three.service
# Update User and paths to match your system
```

Then enable:
```bash
sudo systemctl enable chromix-three
sudo systemctl start chromix-three
```

**For Python server:**

Create `/etc/systemd/system/chromix-three-python.service`:
```ini
[Unit]
Description=Chromix Three Server (Python)
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/path/to/chromix-three/src/server-python
ExecStart=/usr/bin/python3 /path/to/chromix-three/src/server-python/chromix-three-server.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Then enable:
```bash
sudo systemctl enable chromix-three-python
sudo systemctl start chromix-three-python
```

#### Option 2: Startup Applications (GUI)

1. Open "Startup Applications" in your system settings
2. Add new startup program:
   - Name: Chromix Three Server
   - Command: `/path/to/chromix-three/src/server-node/server-start.sh` (Node.js)
   - Or: `/path/to/chromix-three/src/server-python/server-start.sh` (Python)

#### Option 3: Crontab

```bash
crontab -e
```

Add one of these lines:
```
# For Node.js server
@reboot /path/to/chromix-three/src/server-node/server-start.sh

# For Python server
@reboot /path/to/chromix-three/src/server-python/server-start.sh
```

## Troubleshooting

### Server won't start

**For Node.js server:**
```bash
cd src/server-node
./test-install.sh       # Check dependencies
./server-stop.sh        # Stop any hung process
./server-start.sh       # Start fresh
```

**For Python server:**
```bash
cd src/server-python
./server-stop.sh        # Stop any hung process
./server-start.sh       # Start fresh
```

### Extension not connecting

1. Verify server is running: `./server-status.sh` (in respective server directory)
2. Reload extension in Chrome: `chrome://extensions/` (click reload button)
3. Check service worker console for errors (click "service worker" link in extension details)

### Commands not working

1. Check server status: `./server-status.sh`
2. Verify URL pattern matches your tabs
3. Test manually: `curl http://localhost:8444/api/status`
4. Make sure only ONE server is running (Node.js OR Python, not both)

### Port conflicts

If ports 8444 or 7444 are in use, edit:
- Node.js server: `src/server-node/chromix-three-server.js` (HTTP_PORT, WS_PORT)
- Python server: `src/server-python/chromix-three-server.py` (HTTP_PORT, WS_PORT)
- Extension: `src/extension/service-worker.js` (WS_PORT)

**Note:** If you change ports, update them in BOTH the server and extension.

## Migration from chromix-too

If you were using chromix-too:

1. The install script automatically stops chromix-too server
2. chromix-too is not removed or deleted
3. Unload the old chromix-too extension from Chrome
4. Load the new Chromix Three extension
5. Update your scripts to use new command format

### Manually Stop chromix-too Server

If chromix-too server is still running after installation:

```bash
# Find and kill chromix-too-server process
pkill -f chromix-too-server

# Or force kill if needed
pkill -9 -f chromix-too-server

# Verify it's stopped
pgrep -f chromix-too-server
# (should return nothing if stopped)
```

### Main Differences

- HTTP REST API instead of Unix sockets (more portable)
- Wildcard pattern support (`10.10.*.*`)
- Scope parameter for reload (first/all)
- Manifest v3 (future-proof)
- Different ports (8444/7444 instead of 7442)

## API Reference

### POST /api/command

Execute a command.

**Request:**
```json
{
  "command": "reload|list|close|open|ping",
  "url": "optional-url-pattern",
  "scope": "first|all"
}
```

**Response:**
```json
{
  "id": "request-id",
  "success": true,
  "data": "command-specific-data"
}
```

### GET /api/status

Check server and extension connection status.

**Response:**
```json
{
  "connected": true
}
```

## Security

The server listens only on localhost (127.0.0.1) and is not accessible from the network. The extension requires explicit user permission to access tabs and execute commands.

## License

MIT License

Copyright (c) 2025 Vanco Ordanoski / Infoproject LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Contact

Vanco Ordanoski
Email: vordan@infoproject.biz
Company: Infoproject LLC
