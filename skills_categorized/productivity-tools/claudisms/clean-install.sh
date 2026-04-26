#!/usr/bin/env bash
# clean-install.sh - Complete clean slate install
set -euo pipefail

echo "🧹 Cleaning all claudisms traces..."

# Remove ALL claudisms directories
rm -rf ~/.claude/plugins/claudisms
rm -rf ~/.claude/plugins/marketplaces/claudisms

# Clear from config files
echo '{"version":1,"plugins":{}}' > ~/.claude/plugins/installed_plugins.json
echo '{}' > ~/.claude/plugins/known_marketplaces.json

echo "✅ Clean slate ready"
echo ""
echo "Now run: claude mcp add github:jeffersonwarrior/claudisms"
