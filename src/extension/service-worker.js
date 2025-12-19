/**
 * Chromix Three - Chrome Extension Service Worker
 * Connects to local server via WebSocket and executes Chrome API commands
 *
 * Author: Vanco Ordanoski <vordan@infoproject.biz>
 * Company: Infoproject LLC
 * License: MIT
 */

// ============================================================================
// CONFIGURATION
// ============================================================================

const WS_HOST = 'localhost';
const WS_PORT = 7444;
const RECONNECT_DELAY = 5000; // 5 seconds

// ============================================================================
// STATE
// ============================================================================

let socket = null;
let connectionState = 'disconnected'; // disconnected | connecting | connected

// ============================================================================
// CONNECTION MANAGEMENT
// ============================================================================

// Global debugging switch
const debug = false;

/**
 * Connect to WebSocket server
 */
function connect() {
	// Don't connect if already connected or connecting
	if (socket?.readyState === WebSocket.OPEN || socket?.readyState === WebSocket.CONNECTING) {
		return;
	}

	connectionState = 'connecting';
	if (debug) console.log('[Chromix] Connecting to server...');

	try {
		socket = new WebSocket(`ws://${WS_HOST}:${WS_PORT}`);

		socket.onopen = onConnected;
		socket.onmessage = onMessage;
		socket.onclose = onDisconnected;
		socket.onerror = onError;

	} catch (error) {
		console.error('[Chromix] Connection error:', error);
		scheduleReconnect();
	}
}

/**
 * Handle successful connection
 */
function onConnected() {
	connectionState = 'connected';
	if (debug) console.log('[Chromix] Connected to server');
}

/**
 * Handle disconnection
 */
function onDisconnected() {
	connectionState = 'disconnected';
	socket = null;
	if (debug) console.log('[Chromix] Disconnected from server');
	scheduleReconnect();
}

/**
 * Handle connection error
 */
function onError(error) {
	console.error('[Chromix] WebSocket error:', error);
}

/**
 * Schedule reconnection attempt
 */
function scheduleReconnect() {
	if (debug) console.log(`[Chromix] Reconnecting in ${RECONNECT_DELAY}ms...`);
	setTimeout(connect, RECONNECT_DELAY);
}

// ============================================================================
// MESSAGE HANDLING
// ============================================================================

/**
 * Handle incoming message from server
 * @param {MessageEvent} event - WebSocket message event
 */
function onMessage(event) {
	try {
		const request = JSON.parse(event.data);
		if (debug) console.log('[Chromix] Received command:', request.command);

		// Execute command asynchronously
		executeCommand(request);

	} catch (error) {
		console.error('[Chromix] Error parsing message:', error);
	}
}

/**
 * Execute command and send response
 * @param {Object} request - Command request {id, command, url, scope}
 */
async function executeCommand(request) {
	const { id, command, url, scope } = request;

	try {
		let data;

		// Execute command based on type
		switch (command) {
			case 'ping':
				data = 'pong';
				break;

			case 'list':
				data = await listTabs(url);
				break;

			case 'reload':
				data = await reloadTabs(url, scope);
				break;

			case 'close':
				data = await closeTabs(url);
				break;

			case 'open':
				data = await openTab(url);
				break;

			default:
				throw new Error(`Unknown command: ${command}`);
		}

		// Send success response
		sendResponse(id, true, data);

	} catch (error) {
		console.error('[Chromix] Command error:', error);
		sendResponse(id, false, error.message);
	}
}

/**
 * Send response back to server
 * @param {string} id - Request ID
 * @param {boolean} success - Success status
 * @param {*} data - Response data or error message
 */
function sendResponse(id, success, data) {
	if (socket?.readyState === WebSocket.OPEN) {
		const response = { id, success, data };
		socket.send(JSON.stringify(response));
	}
}

// ============================================================================
// CHROME API COMMANDS
// ============================================================================

/**
 * Check if URL matches pattern (supports wildcards)
 * Pattern can use * as wildcard (e.g., "10.10.*.*" or "localhost:*")
 * @param {string} url - URL to test
 * @param {string} pattern - Pattern to match (can include * wildcards)
 * @returns {boolean} True if URL matches pattern
 */
function urlMatches(url, pattern) {
	if (!pattern) return true;

	// If pattern contains *, convert to regex
	if (pattern.includes('*')) {
		// Escape special regex characters except *
		const escapedPattern = pattern
			.replace(/[.+?^${}()|[\]\\]/g, '\\$&')  // Escape special chars
			.replace(/\*/g, '.*');                    // Convert * to .*

		const regex = new RegExp(escapedPattern);
		return regex.test(url);
	}

	// No wildcards, use simple substring match
	return url.includes(pattern);
}

/**
 * List all tabs, optionally filtered by URL pattern
 * @param {string} urlPattern - Optional URL pattern to filter tabs (supports * wildcards)
 * @returns {Promise<Array>} Array of tab objects
 */
async function listTabs(urlPattern) {
	const tabs = await chrome.tabs.query({});

	if (urlPattern) {
		// Filter tabs that match the URL pattern
		return tabs.filter(tab => urlMatches(tab.url, urlPattern)).map(tab => ({
			id: tab.id,
			url: tab.url,
			title: tab.title
		}));
	}

	// Return all tabs
	return tabs.map(tab => ({
		id: tab.id,
		url: tab.url,
		title: tab.title
	}));
}

/**
 * Reload tabs matching URL pattern (or all tabs if no pattern)
 * @param {string} urlPattern - Optional URL pattern to filter tabs (supports * wildcards)
 * @param {string} scope - Scope of reload: 'first' (default) or 'all'
 * @returns {Promise<number>} Number of tabs reloaded
 */
async function reloadTabs(urlPattern, scope = 'first') {
	const tabs = await chrome.tabs.query({});

	// Filter tabs if URL pattern provided
	let matching = urlPattern
		? tabs.filter(tab => urlMatches(tab.url, urlPattern))
		: tabs;

	// If scope is 'first', only reload the first matching tab
	if (scope === 'first' && matching.length > 0) {
		matching = [matching[0]];
	}

	// Reload each matching tab
	for (const tab of matching) {
		await chrome.tabs.reload(tab.id);
	}

	return matching.length;
}

/**
 * Close tabs matching URL pattern
 * @param {string} urlPattern - URL pattern to filter tabs (required, supports * wildcards)
 * @returns {Promise<number>} Number of tabs closed
 */
async function closeTabs(urlPattern) {
	if (!urlPattern) {
		throw new Error('URL pattern required for close command');
	}

	const tabs = await chrome.tabs.query({});
	const matching = tabs.filter(tab => urlMatches(tab.url, urlPattern));

	// Close each matching tab
	const tabIds = matching.map(tab => tab.id);
	if (tabIds.length > 0) {
		await chrome.tabs.remove(tabIds);
	}

	return tabIds.length;
}

/**
 * Open new tab with URL
 * @param {string} url - URL to open (required)
 * @returns {Promise<number>} Tab ID of newly created tab
 */
async function openTab(url) {
	if (!url) {
		throw new Error('URL required for open command');
	}

	const tab = await chrome.tabs.create({ url });
	return tab.id;
}

// ============================================================================
// SERVICE WORKER LIFECYCLE
// ============================================================================

// Connect on service worker startup
connect();

// Reconnect when extension is installed or updated
chrome.runtime.onInstalled.addListener(() => {
	if (debug) console.log('[Chromix] Extension installed/updated');
	connect();
});

// Reconnect when browser starts
chrome.runtime.onStartup.addListener(() => {
	if (debug) console.log('[Chromix] Browser started');
	connect();
});

// Keep-alive: ping every 20 seconds to prevent service worker termination
chrome.alarms.create('keepAlive', {
	periodInMinutes: 1/3  // 20 seconds
});

chrome.alarms.onAlarm.addListener((alarm) => {
	if (alarm.name === 'keepAlive') {
		// This keeps the service worker alive
		// Also try to reconnect if disconnected
		if (connectionState === 'disconnected') {
			connect();
		}
	}
});

if (debug) console.log('[Chromix] Service worker initialized');
