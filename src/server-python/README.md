# Chromix Three - Python Server

Alternative Python implementation of the Chromix Three server. Provides identical functionality to the Node.js version without requiring Node.js installation.

## Why Python?

- **No Node.js required**: Python 3.7+ is pre-installed on most Linux systems
- **Smaller footprint**: Uses standard Python libraries + 2 small packages
- **Identical protocol**: Works with the same Chrome extension without any modifications
- **Same ports**: HTTP 8444, WebSocket 7444

## Requirements

- Python 3.7 or higher (usually pre-installed on Linux)
- pip3 (Python package manager)

## Installation

### 1. Install Python Dependencies

```bash
cd src/server-python
pip3 install websockets aiohttp
```

Or if you prefer a virtual environment:

```bash
cd src/server-python
python3 -m venv venv
source venv/bin/activate
pip install websockets aiohttp
```

### 2. Make Script Executable

```bash
chmod +x chromix-three-server.py
```

## Usage

### Start Server

```bash
# Direct execution
python3 chromix-three-server.py

# Or if executable
./chromix-three-server.py

# With virtual environment
source venv/bin/activate
python chromix-three-server.py
```

### Stop Server

Press `Ctrl+C` or:

```bash
pkill -f chromix-three-server.py
```

### Check if Running

```bash
pgrep -f chromix-three-server.py
# Or
curl http://localhost:8444/api/status
```

## Testing

The Python server is 100% compatible with the Node.js version. All the same scripts work:

```bash
# Use existing helper scripts
cd ../scripts
./chromix-three-reload.sh  # Works with Python server!

# Manual test
curl -X POST http://localhost:8444/api/command \
  -H "Content-Type: application/json" \
  -d '{"command":"reload","url":"10.10.*.*"}'
```

## Chrome Extension

**No changes needed!** The Chrome extension works identically with both Node.js and Python servers. Just make sure only one server is running at a time.

## Comparison with Node.js Version

| Feature | Node.js | Python |
|---------|---------|--------|
| HTTP Server | Built-in | aiohttp |
| WebSocket | ws package | websockets package |
| Ports | 8444, 7444 | 8444, 7444 |
| Protocol | Identical | Identical |
| Extension compatibility | ✓ | ✓ |
| Installation footprint | ~50MB | ~5MB |
| Pre-installed | Rarely | Usually (Linux) |

## Running Both Versions

You can switch between Node.js and Python servers:

```bash
# Stop Node.js server
cd ../scripts
./server-stop.sh

# Start Python server
cd ../server-python
python3 chromix-three-server.py
```

Or vice versa:

```bash
# Stop Python server
pkill -f chromix-three-server.py

# Start Node.js server
cd ../scripts
./server-start.sh
```

## Systemd Service (Optional)

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

Enable and start:

```bash
sudo systemctl enable chromix-three-python
sudo systemctl start chromix-three-python
```

## Troubleshooting

### Missing Dependencies

```bash
pip3 install websockets aiohttp
```

### Port Already in Use

Make sure the Node.js server isn't running:

```bash
cd ../scripts
./server-stop.sh
```

### Permission Denied

Make the script executable:

```bash
chmod +x chromix-three-server.py
```

## License

MIT License - Same as Chromix Three main project

## Author

Vanco Ordanoski <vordan@infoproject.biz>  
Company: Infoproject LLC
