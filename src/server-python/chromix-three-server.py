#!/usr/bin/env python3
"""
Chromix Three Server - Python Implementation.

Alternative to Node.js server with identical functionality. This server provides
a local HTTP REST API and WebSocket server for controlling Chrome browser tabs
via the Chromix Three extension.

The server listens on two ports:
- HTTP API (8444): Receives commands from CLI/scripts via POST requests
- WebSocket (7444): Maintains persistent connection to Chrome extension

Author: Vanco Ordanoski <vordan@infoproject.biz>
Company: Infoproject LLC
License: MIT

Requirements:
    pip install websockets aiohttp

Usage:
    python3 chromix-three-server.py
"""

import asyncio
import json
import signal
import sys
from datetime import datetime
from typing import Optional, Dict, Any

import websockets
from aiohttp import web

# ============================================================================
# CONFIGURATION
# ============================================================================

# Port for HTTP REST API (receives commands from CLI)
HTTP_PORT = 8444

# Port for WebSocket server (connects to Chrome extension)
WS_PORT = 7444

# Request timeout in seconds
REQUEST_TIMEOUT = 10.0

# ============================================================================
# STATE
# ============================================================================

# Single extension WebSocket connection
# Only one Chrome extension connects at a time (single-user design)
extension_socket: Optional[websockets.WebSocketServerProtocol] = None

# Pending request waiting for response from extension
# Only ONE request can be pending at a time (single-user scenario)
pending_request: Optional[Dict[str, Any]] = None

# Request ID counter for generating unique request identifiers
request_id_counter = 0


# ============================================================================
# REQUEST ID GENERATOR
# ============================================================================

def generate_request_id() -> str:
    """
    Generate unique request ID.

    Creates a unique identifier for each request using timestamp and counter.
    Format: req-{milliseconds}-{counter}

    Returns:
        str: Unique request ID (e.g., "req-1703073600000-1")
    """
    global request_id_counter
    request_id_counter += 1
    timestamp = int(datetime.now().timestamp() * 1000)
    return f"req-{timestamp}-{request_id_counter}"


# ============================================================================
# WEBSOCKET SERVER
# ============================================================================

async def handle_extension_connection(
    websocket: websockets.WebSocketServerProtocol,
    path: str
) -> None:
    """
    Handle WebSocket connection from Chrome extension.

    Maintains a persistent connection to the Chrome extension and processes
    incoming response messages. Only one extension connection is supported
    at a time.

    Args:
        websocket: WebSocket connection from the Chrome extension
        path: WebSocket connection path (unused but required by websockets API)
    """
    global extension_socket

    print("[WebSocket] Extension connected")
    extension_socket = websocket

    try:
        # Process incoming messages until connection closes
        async for message in websocket:
            await handle_extension_response(message)
    except websockets.exceptions.ConnectionClosed:
        print("[WebSocket] Extension disconnected")
    finally:
        extension_socket = None

        # Reject any pending request if extension disconnects
        global pending_request
        if pending_request:
            pending_request['future'].set_exception(
                Exception("Extension disconnected")
            )
            pending_request = None


async def handle_extension_response(data: str) -> None:
    """
    Handle response message from Chrome extension.

    Parses the JSON response and resolves the pending request future.
    Matches responses to requests using the unique request ID.

    Args:
        data: JSON string containing response from extension
              Expected format: {"id": "req-123", "success": bool, "data": any}
    """
    global pending_request

    try:
        response = json.loads(data)

        # Check if we have a pending request matching this response
        if pending_request and pending_request['id'] == response['id']:
            if response['success']:
                # Resolve future with successful response
                pending_request['future'].set_result(response)
            else:
                # Reject future with error
                error_msg = response.get('data', 'Unknown error')
                pending_request['future'].set_exception(Exception(error_msg))
            pending_request = None

    except json.JSONDecodeError as e:
        print(f"[WebSocket] Error parsing response: {e}")


async def send_to_extension(request: Dict[str, Any]) -> Dict[str, Any]:
    """
    Send request to Chrome extension and wait for response.

    Creates a future that will be resolved when the extension sends back
    a response message. Uses asyncio.wait_for to implement timeout.

    Args:
        request: Command request to send to extension
                 Must contain 'id' field for response matching

    Returns:
        dict: Response from extension with format:
              {"id": str, "success": bool, "data": any}

    Raises:
        Exception: If extension is not connected
        Exception: If request times out (10 seconds)
    """
    global pending_request

    # Check if extension is connected
    if not extension_socket or extension_socket.closed:
        raise Exception("Extension not connected")

    # Create future for response
    loop = asyncio.get_event_loop()
    future = loop.create_future()

    # Store pending request for response matching
    pending_request = {
        'id': request['id'],
        'future': future
    }

    # Send request to extension
    try:
        await extension_socket.send(json.dumps(request))

        # Wait for response with timeout
        response = await asyncio.wait_for(future, timeout=REQUEST_TIMEOUT)
        return response

    except asyncio.TimeoutError:
        pending_request = None
        raise Exception("Request timeout")
    except Exception as e:
        pending_request = None
        raise e


def is_connected() -> bool:
    """
    Check if Chrome extension is currently connected.

    Returns:
        bool: True if extension WebSocket is connected, False otherwise
    """
    return extension_socket is not None and not extension_socket.closed


# ============================================================================
# HTTP SERVER
# ============================================================================

async def handle_status(request: web.Request) -> web.Response:
    """
    Handle GET /api/status endpoint.

    Returns the current connection status of the Chrome extension.

    Args:
        request: HTTP request object (unused)

    Returns:
        web.Response: JSON response with format:
                      {"connected": bool}
    """
    return web.json_response({'connected': is_connected()})


async def handle_command(request: web.Request) -> web.Response:
    """
    Handle POST /api/command endpoint.

    Receives command from CLI/script, forwards to Chrome extension via WebSocket,
    and returns the extension's response.

    Supported commands: reload, list, close, open, ping

    Args:
        request: HTTP POST request with JSON body
                 Expected format: {"command": str, "url": str (optional),
                                   "scope": str (optional)}

    Returns:
        web.Response: JSON response from extension or error message

    HTTP Status Codes:
        200: Command executed successfully
        400: Invalid request (missing command, invalid JSON)
        500: Server error (extension disconnected, timeout, etc.)
    """
    try:
        # Parse request body
        body = await request.json()

        # Validate request - command field is required
        if 'command' not in body:
            return web.json_response(
                {'error': 'Missing command field'},
                status=400
            )

        # Generate unique request ID for response matching
        body['id'] = generate_request_id()

        # Log command for debugging
        url_part = f" ({body['url']})" if 'url' in body else ''
        print(f"[HTTP] Command: {body['command']}{url_part}")

        # Send to extension and wait for response
        response = await send_to_extension(body)

        return web.json_response(response)

    except json.JSONDecodeError:
        return web.json_response(
            {'error': 'Invalid JSON'},
            status=400
        )
    except Exception as e:
        print(f"[HTTP] Error: {e}")
        return web.json_response(
            {'success': False, 'error': str(e)},
            status=500
        )


@web.middleware
async def handle_cors(request: web.Request, handler) -> web.Response:
    """
    CORS middleware to allow cross-origin requests.

    Adds CORS headers to all responses for browser testing.
    In production, the server only accepts localhost connections.

    Args:
        request: HTTP request
        handler: Next handler in middleware chain

    Returns:
        web.Response: Response with CORS headers added
    """
    # Handle preflight OPTIONS requests
    if request.method == 'OPTIONS':
        return web.Response(
            headers={
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            }
        )

    # Process request and add CORS headers to response
    response = await handler(request)
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response


# ============================================================================
# MAIN
# ============================================================================

async def main() -> None:
    """
    Start WebSocket and HTTP servers.

    Initializes both servers and keeps them running indefinitely.
    The WebSocket server listens for Chrome extension connections,
    while the HTTP server receives commands from CLI/scripts.

    Both servers bind to localhost only for security.
    """
    # Start WebSocket server for Chrome extension connection
    ws_server = await websockets.serve(
        handle_extension_connection,
        'localhost',
        WS_PORT
    )
    print(f"[WebSocket] Server listening on port {WS_PORT}")

    # Create HTTP server for CLI commands
    app = web.Application(middlewares=[handle_cors])
    app.router.add_get('/api/status', handle_status)
    app.router.add_post('/api/command', handle_command)

    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, 'localhost', HTTP_PORT)
    await site.start()

    print(f"[HTTP] Server listening on port {HTTP_PORT}")
    print("")
    print("Chromix Three Server is running!")
    print("")
    print("Usage:")
    print("  curl -X POST http://localhost:8444/api/command \\")
    print("    -H \"Content-Type: application/json\" \\")
    print("    -d '{\"command\":\"reload\",\"url\":\"localhost:3000\"}'")
    print("")
    print("Status:")
    print("  curl http://localhost:8444/api/status")
    print("")

    # Keep running indefinitely
    await asyncio.Future()


def shutdown(signum: int, frame) -> None:
    """
    Handle shutdown signals (SIGINT, SIGTERM).

    Performs graceful shutdown when receiving interrupt signals.

    Args:
        signum: Signal number
        frame: Current stack frame (unused)
    """
    print("")
    print("[Server] Shutting down...")
    sys.exit(0)


if __name__ == '__main__':
    # Register signal handlers for graceful shutdown
    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    # Check if required dependencies are installed
    try:
        import websockets
        import aiohttp
    except ImportError as e:
        print("Error: Missing required dependencies")
        print("")
        print("Install with:")
        print("  pip3 install websockets aiohttp")
        print("")
        sys.exit(1)

    # Run server
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("")
        print("[Server] Stopped")
