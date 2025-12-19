# Chromix Three - Helper Scripts

Version: 1.0.1  
Date: December 19, 2025

Collection of bash scripts to manage and use Chromix Three.

## Installation & Setup

### install.sh
Installs Chromix Three server and deactivates chromix-too if running.

**Usage:**
```bash
./install.sh
```

**What it does:**
- Checks if Node.js, npm, and curl are installed
- Stops chromix-too server if running (does not remove it)
- Installs server dependencies (npm install)
- Shows next steps for setup

### test-install.sh
Checks if all required dependencies are installed (Node.js, npm, curl, server packages).

**Usage:**
```bash
./test-install.sh
```

## Server Management

### server-start.sh
Starts the Chromix Three server in the background.

**Usage:**
```bash
./server-start.sh
```

**What it does:**
- Checks if Node.js and curl are installed
- Checks if server is already running
- Starts server on ports 8444 (HTTP) and 7444 (WebSocket)

### server-stop.sh
Stops the Chromix Three server.

**Usage:**
```bash
./server-stop.sh
```

**What it does:**
- Finds the server process
- Gracefully stops it (or force kills if needed)

### server-status.sh
Checks server and extension status.

**Usage:**
```bash
./server-status.sh
```

**What it does:**
- Checks if server process is running
- Checks if HTTP API is responding
- Checks if Chrome extension is connected
- Provides helpful instructions if something is not working

## Development Commands

### chromix-three-reload.sh
**Main script for development workflow!**

Reloads the first Chrome tab matching the pattern `10.10.*.*` (your dev server).

**Usage:**
```bash
./chromix-three-reload.sh
```

**What it does:**
- Checks if curl is installed
- Sends reload command to server
- Reloads first tab matching `10.10.*.*` pattern
- Shows success/error message

**Use in your editor (Geany):**
Add this to your custom commands and bind to Ctrl+F1:
```bash
/path/to/chromix-three/scripts/chromix-three-reload.sh
```

## Making Scripts Executable

After cloning or downloading, make scripts executable:

```bash
chmod +x *.sh
```

## Typical Workflow

1. **First time setup:**
   ```bash
   ./install.sh
   ./server-start.sh
   ```

2. **Load extension in Chrome:**
   - Open `chrome://extensions/`
   - Enable "Developer mode"
   - Click "Load unpacked"
   - Select `chromix-three/extension/` folder

3. **Check everything is working:**
   ```bash
   ./server-status.sh
   ```

4. **During development:**
   - Edit your code
   - Press Ctrl+F1 (or run `./chromix-three-reload.sh`)
   - Your dev server tab reloads automatically!

5. **When done:**
   ```bash
   ./server-stop.sh
   ```

## Customizing URL Pattern

To reload tabs with a different URL pattern, edit `chromix-three-reload.sh` and change:

```bash
URL_PATTERN="10.10.*.*"
```

To any pattern you need:
- `localhost:*` - All localhost tabs
- `http://10.*` - All 10.x.x.x addresses
- `example.com` - Any tab with example.com

## Troubleshooting

**Server won't start?**
```bash
./test-install.sh  # Check dependencies
./server-stop.sh   # Stop any hung process
./server-start.sh  # Start fresh
```

**Extension not connecting?**
1. Make sure server is running: `./server-status.sh`
2. Reload extension in Chrome (`chrome://extensions/`)
3. Check extension console for errors

**Reload not working?**
1. Check status: `./server-status.sh`
2. Make sure your tab URL matches the pattern `10.10.*.*`
3. Test manually: `curl http://localhost:8080/api/status`

---

**Version:** 1.0.1  
**Date:** December 19, 2025
**Author:** Vanco Ordanoski <vordan@infoproject.biz>  
**Company:** Infoproject LLC  
**License:** MIT
