#!/usr/bin/env node
/**
 * Chromix Three Server
 * Main server handling HTTP API and WebSocket connection to Chrome extension
 * 
 * Author: Vanco Ordanoski <vordan@infoproject.biz>
 * Company: Infoproject LLC
 * License: MIT
 */

const http = require('http');
const { createWebSocketServer, sendToExtension, isConnected } = require('./websocket');

// ============================================================================
// CONFIGURATION
// ============================================================================

const HTTP_PORT = 8444;
const WS_PORT = 7444;

// Request ID generator
let requestIdCounter = 0;
function generateRequestId() {
	return `req-${Date.now()}-${++requestIdCounter}`;
}

// ============================================================================
// HTTP SERVER
// ============================================================================

/**
 * Read request body
 * @param {http.IncomingMessage} req - HTTP request
 * @returns {Promise<string>} Request body as string
 */
function getRequestBody(req) {
	return new Promise((resolve, reject) => {
		let body = '';
		req.on('data', chunk => {
			body += chunk.toString();
		});
		req.on('end', () => {
			resolve(body);
		});
		req.on('error', reject);
	});
}

/**
 * Handle HTTP request
 * @param {http.IncomingMessage} req - HTTP request
 * @param {http.ServerResponse} res - HTTP response
 */
async function handleRequest(req, res) {
	// Enable CORS (for browser testing if needed)
	res.setHeader('Access-Control-Allow-Origin', '*');
	res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
	res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
	
	// Handle preflight
	if (req.method === 'OPTIONS') {
		res.writeHead(200);
		res.end();
		return;
	}
	
	// GET /api/status - Check if extension is connected
	if (req.url === '/api/status' && req.method === 'GET') {
		res.writeHead(200, { 'Content-Type': 'application/json' });
		res.end(JSON.stringify({ connected: isConnected() }));
		return;
	}
	
	// POST /api/command - Execute command
	if (req.url === '/api/command' && req.method === 'POST') {
		try {
			// Parse request body
			const body = await getRequestBody(req);
			const request = JSON.parse(body);
			
			// Validate request
			if (!request.command) {
				res.writeHead(400, { 'Content-Type': 'application/json' });
				res.end(JSON.stringify({ error: 'Missing command field' }));
				return;
			}
			
			// Generate unique request ID
			request.id = generateRequestId();
			
			console.log(`[HTTP] Command: ${request.command}${request.url ? ` (${request.url})` : ''}`);
			
			// Send to extension and wait for response
			const response = await sendToExtension(request);
			
			// Return response to client
			res.writeHead(200, { 'Content-Type': 'application/json' });
			res.end(JSON.stringify(response));
			
		} catch (error) {
			console.error('[HTTP] Error:', error.message);
			res.writeHead(500, { 'Content-Type': 'application/json' });
			res.end(JSON.stringify({ 
				success: false,
				error: error.message 
			}));
		}
		return;
	}
	
	// 404 for other routes
	res.writeHead(404, { 'Content-Type': 'application/json' });
	res.end(JSON.stringify({ error: 'Not found' }));
}

// Create HTTP server
const httpServer = http.createServer(handleRequest);

// ============================================================================
// STARTUP
// ============================================================================

// Start WebSocket server
createWebSocketServer(WS_PORT);

// Start HTTP server
httpServer.listen(HTTP_PORT, () => {
	console.log(`[HTTP] Server listening on port ${HTTP_PORT}`);
	console.log('');
	console.log('Chromix Three Server is running!');
	console.log('');
	console.log('Usage:');
	console.log('  curl -X POST http://localhost:8080/api/command \\');
	console.log('    -H "Content-Type: application/json" \\');
	console.log('    -d \'{"command":"reload","url":"localhost:3000"}\'');
	console.log('');
	console.log('Status:');
	console.log('  curl http://localhost:8080/api/status');
	console.log('');
});

// ============================================================================
// GRACEFUL SHUTDOWN
// ============================================================================

function shutdown() {
	console.log('');
	console.log('[Server] Shutting down...');
	httpServer.close(() => {
		console.log('[Server] Stopped');
		process.exit(0);
	});
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
