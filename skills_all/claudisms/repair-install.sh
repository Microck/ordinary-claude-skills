#!/usr/bin/env bash
# repair-install.sh - Fix all claudisms installation issues
set -euo pipefail

PLUGIN_NAME="claudisms"
MARKETPLACE_DIR="${HOME}/.claude/plugins/marketplaces/${PLUGIN_NAME}"
INSTALLED_PLUGINS="${HOME}/.claude/plugins/installed_plugins.json"
KNOWN_MARKETPLACES="${HOME}/.claude/plugins/known_marketplaces.json"

echo "🔧 Claudisms Installation Repair"
echo "================================="

# 1. Remove old claudisms directory (legacy location)
if [[ -d ~/.claude/plugins/claudisms ]]; then
  echo "✓ Removing legacy plugin directory..."
  rm -rf ~/.claude/plugins/claudisms
fi

# 2. Clean slate: remove existing marketplace directory
if [[ -d "$MARKETPLACE_DIR" ]]; then
  echo "✓ Removing existing marketplace directory..."
  rm -rf "$MARKETPLACE_DIR"
fi

# 3. Create proper marketplace structure
MARKETPLACE_ROOT="${HOME}/.claude/plugins/marketplaces/claudisms"
PLUGIN_DIR="$MARKETPLACE_ROOT/claudisms"

mkdir -p "$PLUGIN_DIR"

# 4. Copy plugin files to plugin subdirectory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "$SCRIPT_DIR" ]]; then
  echo "✓ Syncing plugin files to $PLUGIN_DIR..."
  rsync -av --exclude='.git' --exclude='tmp/' "$SCRIPT_DIR/" "$PLUGIN_DIR/"
fi

# 5. Create marketplace.json at marketplace root
echo "✓ Creating marketplace.json at root..."
mkdir -p "$MARKETPLACE_ROOT/.claude-plugin"
cat > "$MARKETPLACE_ROOT/.claude-plugin/marketplace.json" << 'EOF'
{
  "name": "claudisms",
  "owner": {
    "name": "Jefferson Warrior"
  },
  "plugins": [
    {
      "name": "claudisms",
      "source": "./claudisms",
      "description": "Operational guidelines: terse responses, sequential execution, no destructive ops without confirmation"
    }
  ]
}
EOF

# 6. Update installed_plugins.json
echo "✓ Updating installed_plugins.json..."
cat > "$INSTALLED_PLUGINS" << EOF
{
  "version": 1,
  "plugins": {
    "claudisms@claudisms": {
      "version": "2.2.0",
      "installedAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
      "lastUpdated": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)",
      "installPath": "$PLUGIN_DIR/",
      "gitCommitSha": "$(cd "$SCRIPT_DIR" && git rev-parse HEAD 2>/dev/null || echo 'local')",
      "isLocal": true
    }
  }
}
EOF

# 7. Update known_marketplaces.json
echo "✓ Updating known_marketplaces.json..."
cat > "$KNOWN_MARKETPLACES" << EOF
{
  "claudisms": {
    "source": {
      "url": "https://github.com/jeffersonwarrior/claudisms.git",
      "ref": "main"
    },
    "installLocation": "$MARKETPLACE_ROOT",
    "lastUpdated": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  }
}
EOF

# 8. Initialize settings if not exists
if [[ ! -f "$PLUGIN_DIR/settings.json" ]]; then
  echo "✓ Creating default settings.json..."
  cp "$PLUGIN_DIR/settings.example.json" "$PLUGIN_DIR/settings.json"
fi

# 9. Set permissions
chmod +x "$PLUGIN_DIR"/bin/* 2>/dev/null || true
chmod +x "$PLUGIN_DIR"/hooks-handlers/* 2>/dev/null || true
chmod +x "$PLUGIN_DIR"/commands/*.sh 2>/dev/null || true
chmod +x "$PLUGIN_DIR"/lib/*.sh 2>/dev/null || true

# 10. Verify installation
echo ""
echo "✅ Installation repaired!"
echo ""
echo "Marketplace: $MARKETPLACE_ROOT"
echo "Plugin: $PLUGIN_DIR"
echo "Plugin ID: claudisms@claudisms"
echo ""
echo "Structure:"
echo "  ~/.claude/plugins/marketplaces/claudisms/"
echo "    ├── .claude-plugin/marketplace.json"
echo "    └── claudisms/ (plugin files)"
echo ""
echo "Files installed:"
ls -lh "$PLUGIN_DIR" | tail -n +2 | wc -l | xargs echo "  Files:"
echo ""
echo "⚠️  Restart Claude Code to load changes"
echo ""
echo "Test with: /claudisms-settings"
