/**
 * WebSocket handler for Chrome extension connection
 * Handles single extension connection and request/response routing
 * 
 * Author: Vanco Ordanoski <vordan@infoproject.biz>
 * Company: Infoproject LLC
 * License: MIT
 */

const { WebSocketServer } = require('ws');

// ============================================================================
// STATE
// ============================================================================

// Single extension connection (only one extension connects)
let extensionSocket = null;

// Pending request waiting for response from extension
// Only ONE request can be pending at a time (single user scenario)
let pendingRequest = null;

// ============================================================================
// WEBSOCKET SERVER SETUP
// ============================================================================

/**
 * Create and start WebSocket server
 * @param {number} port - Port to listen on (default: 7443)
 * @returns {WebSocketServer} WebSocket server instance
 */
function createWebSocketServer(port = 7443) {
	const wss = new WebSocketServer({ port });
	
	console.log(`[WebSocket] Server listening on port ${port}`);
	
	// Handle new connection from extension
	wss.on('connection', (socket) => {
		console.log('[WebSocket] Extension connected');
		
		// Store the extension socket
		extensionSocket = socket;
		
		// Handle incoming messages from extension (responses)
		socket.on('message', (data) => {
			handleExtensionResponse(data);
		});
		
		// Handle disconnection
		socket.on('close', () => {
			console.log('[WebSocket] Extension disconnected');
			extensionSocket = null;
			
			// Reject pending request if any
			if (pendingRequest) {
				pendingRequest.reject(new Error('Extension disconnected'));
				pendingRequest = null;
			}
		});
		
		// Handle errors
		socket.on('error', (error) => {
			console.error('[WebSocket] Error:', error.message);
		});
	});
	
	return wss;
}

// ============================================================================
// REQUEST/RESPONSE HANDLING
// ============================================================================

/**
 * Send request to extension and wait for response
 * @param {Object} request - Request object {id, command, url}
 * @returns {Promise<Object>} Response from extension
 */
function sendToExtension(request) {
	return new Promise((resolve, reject) => {
		// Check if extension is connected
		if (!extensionSocket || extensionSocket.readyState !== 1) {
			reject(new Error('Extension not connected'));
			return;
		}
		
		// Store the pending request
		pendingRequest = {
			id: request.id,
			resolve,
			reject,
			timeout: setTimeout(() => {
				pendingRequest = null;
				reject(new Error('Request timeout'));
			}, 10000) // 10 second timeout
		};
		
		// Send request to extension
		try {
			extensionSocket.send(JSON.stringify(request));
		} catch (error) {
			clearTimeout(pendingRequest.timeout);
			pendingRequest = null;
			reject(error);
		}
	});
}

/**
 * Handle response from extension
 * @param {Buffer|String} data - Response data from extension
 */
function handleExtensionResponse(data) {
	try {
		const response = JSON.parse(data.toString());
		
		// Check if we have a pending request matching this response
		if (pendingRequest && pendingRequest.id === response.id) {
			clearTimeout(pendingRequest.timeout);
			
			if (response.success) {
				pendingRequest.resolve(response);
			} else {
				pendingRequest.reject(new Error(response.data || 'Unknown error'));
			}
			
			pendingRequest = null;
		}
	} catch (error) {
		console.error('[WebSocket] Error parsing response:', error.message);
	}
}

/**
 * Check if extension is connected
 * @returns {boolean} Connection status
 */
function isConnected() {
	return extensionSocket !== null && extensionSocket.readyState === 1;
}

// ============================================================================
// EXPORTS
// ============================================================================

module.exports = {
	createWebSocketServer,
	sendToExtension,
	isConnected
};
