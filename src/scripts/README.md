# Chromix Three - Shared Scripts

Version: 1.2.0  
Date: December 20, 2025

Shared scripts that work with both Node.js and Python servers.

**Note:** Server-specific management scripts (install, start, stop, status) have been moved to their respective server directories:
- Node.js scripts: `../server-node/`
- Python scripts: `../server-python/`

## chromix-three-reload.sh
**Main script for development workflow!**

Reloads the first Chrome tab matching the pattern `10.10.*.*` (your dev server).

**Works with both Node.js and Python servers** - just make sure one is running.

**Usage:**
```bash
./chromix-three-reload.sh
```

**What it does:**
- Checks if curl is installed
- Sends reload command to server (localhost:8444)
- Reloads first tab matching `10.10.*.*` pattern
- Shows success/error message

**Use in your editor (Geany, VS Code, etc):**
Add this to your custom commands and bind to a keyboard shortcut:
```bash
/path/to/chromix-three/src/scripts/chromix-three-reload.sh
```

### Customizing URL Pattern

To reload tabs with a different URL pattern, edit `chromix-three-reload.sh` and change:

```bash
URL_PATTERN="10.10.*.*"
```

To any pattern you need:
- `localhost:*` - All localhost tabs
- `http://10.*` - All 10.x.x.x addresses
- `*.example.com` - Any subdomain

---

**Version:** 1.2.0  
**Date:** December 20, 2025  
**Author:** Vanco Ordanoski <vordan@infoproject.biz>  
**Company:** Infoproject LLC  
**License:** MIT
