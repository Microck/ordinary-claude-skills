#!/bin/bash
# Claude Code Plugin Uninstaller
# Completely removes plugin configuration and files

set -e

CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
INSTALLED_PLUGINS_FILE="$PLUGINS_DIR/installed_plugins.json"
KNOWN_MARKETPLACES_FILE="$PLUGINS_DIR/known_marketplaces.json"
MARKETPLACES_DIR="$PLUGINS_DIR/marketplaces"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
SETTINGS_LOCAL_FILE="$CLAUDE_DIR/settings.local.json"

echo "🧹 Claude Code Plugin Uninstaller"
echo "=================================="
echo ""

# Check if Claude directory exists
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "❌ Claude directory not found: $CLAUDE_DIR"
    exit 1
fi

# Backup current configuration
BACKUP_DIR="$HOME/.claude-plugin-backup-$(date +%Y%m%d-%H%M%S)"
echo "📦 Creating backup at: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
if [ -f "$INSTALLED_PLUGINS_FILE" ]; then
    cp "$INSTALLED_PLUGINS_FILE" "$BACKUP_DIR/"
fi
if [ -f "$KNOWN_MARKETPLACES_FILE" ]; then
    cp "$KNOWN_MARKETPLACES_FILE" "$BACKUP_DIR/"
fi
if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$BACKUP_DIR/"
fi
if [ -f "$SETTINGS_LOCAL_FILE" ]; then
    cp "$SETTINGS_LOCAL_FILE" "$BACKUP_DIR/"
fi
if [ -d "$MARKETPLACES_DIR" ]; then
    cp -r "$MARKETPLACES_DIR" "$BACKUP_DIR/" 2>/dev/null || true
fi
echo "✅ Backup created"
echo ""

# Show current plugins
echo "📋 Current installed plugins:"
if [ -f "$INSTALLED_PLUGINS_FILE" ]; then
    cat "$INSTALLED_PLUGINS_FILE" | grep -oP '"[^"]+@[^"]+"' | tr -d '"' || echo "  (none found)"
else
    echo "  No installed_plugins.json file found"
fi
echo ""

# Interactive mode: ask which plugin to remove
if [ $# -eq 0 ]; then
    echo "Usage: $0 [plugin-name] or $0 --all"
    echo ""
    echo "Options:"
    echo "  <plugin-name>  Remove specific plugin (e.g., claudeisms@claudisms)"
    echo "  --all          Remove all plugins and reset configuration"
    echo "  --list         List all installed plugins"
    echo ""

    # Auto-detect broken plugins
    if [ -f "$INSTALLED_PLUGINS_FILE" ]; then
        echo "🔍 Checking for broken plugins..."
        BROKEN_PLUGINS=$(cat "$INSTALLED_PLUGINS_FILE" | grep -oP '"[^"]+@[^"]+"' | tr -d '"' || true)

        if [ -n "$BROKEN_PLUGINS" ]; then
            echo "Found plugins:"
            while IFS= read -r plugin; do
                PLUGIN_PATH=$(cat "$INSTALLED_PLUGINS_FILE" | grep -A 10 "\"$plugin\"" | grep "installPath" | grep -oP '": "\K[^"]+' || true)
                if [ -n "$PLUGIN_PATH" ] && [ ! -d "$PLUGIN_PATH" ]; then
                    echo "  ⚠️  $plugin (MISSING FILES at $PLUGIN_PATH)"
                else
                    echo "  ✓  $plugin"
                fi
            done <<< "$BROKEN_PLUGINS"
        fi
    fi

    exit 0
fi

# Handle arguments
if [ "$1" = "--list" ]; then
    echo "Installed plugins:"
    if [ -f "$INSTALLED_PLUGINS_FILE" ]; then
        cat "$INSTALLED_PLUGINS_FILE" | jq -r '.plugins | keys[]' 2>/dev/null || cat "$INSTALLED_PLUGINS_FILE" | grep -oP '"[^"]+@[^"]+"' | tr -d '"'
    fi
    exit 0
fi

if [ "$1" = "--all" ]; then
    echo "⚠️  This will remove ALL plugins and reset plugin configuration!"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Cancelled"
        exit 0
    fi

    echo ""
    echo "🗑️  Removing all plugins..."

    # Reset installed_plugins.json
    if [ -f "$INSTALLED_PLUGINS_FILE" ]; then
        echo '{"version":1,"plugins":{}}' > "$INSTALLED_PLUGINS_FILE"
        echo "✅ Reset installed_plugins.json"
    fi

    # Reset known_marketplaces.json
    if [ -f "$KNOWN_MARKETPLACES_FILE" ]; then
        echo '{}' > "$KNOWN_MARKETPLACES_FILE"
        echo "✅ Reset known_marketplaces.json"
    fi

    # Remove all marketplace directories
    if [ -d "$MARKETPLACES_DIR" ]; then
        rm -rf "$MARKETPLACES_DIR"/*
        echo "✅ Removed all marketplace directories"
    fi

    # Clean settings.json enabledPlugins
    if [ -f "$SETTINGS_FILE" ]; then
        python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    data = json.load(f)
if 'enabledPlugins' in data:
    data['enabledPlugins'] = {}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null && echo "✅ Cleaned settings.json"
    fi

    # Clean settings.local.json enabledPlugins
    if [ -f "$SETTINGS_LOCAL_FILE" ]; then
        python3 -c "
import json
with open('$SETTINGS_LOCAL_FILE', 'r') as f:
    data = json.load(f)
if 'enabledPlugins' in data:
    data['enabledPlugins'] = {}
with open('$SETTINGS_LOCAL_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null && echo "✅ Cleaned settings.local.json"
    fi

    echo ""
    echo "✅ All plugins removed successfully!"
    echo "📦 Backup saved at: $BACKUP_DIR"
    exit 0
fi

# Remove specific plugin
PLUGIN_NAME="$1"
echo "🗑️  Removing plugin: $PLUGIN_NAME"
echo ""

# Check if plugin exists in configuration
if [ ! -f "$INSTALLED_PLUGINS_FILE" ]; then
    echo "❌ No installed_plugins.json file found"
    exit 1
fi

# Get plugin install path
PLUGIN_PATH=$(cat "$INSTALLED_PLUGINS_FILE" | grep -A 10 "\"$PLUGIN_NAME\"" | grep "installPath" | grep -oP '": "\K[^"]+' || true)

# Remove from installed_plugins.json using jq if available, otherwise use sed
if command -v jq &> /dev/null; then
    echo "📝 Removing from installed_plugins.json (using jq)..."
    TMP_FILE=$(mktemp)
    jq "del(.plugins[\"$PLUGIN_NAME\"])" "$INSTALLED_PLUGINS_FILE" > "$TMP_FILE"
    mv "$TMP_FILE" "$INSTALLED_PLUGINS_FILE"
    echo "✅ Removed from configuration"
else
    echo "⚠️  jq not available, using manual removal..."
    # This is more fragile but works without jq
    python3 -c "
import json
with open('$INSTALLED_PLUGINS_FILE', 'r') as f:
    data = json.load(f)
if 'plugins' in data and '$PLUGIN_NAME' in data['plugins']:
    del data['plugins']['$PLUGIN_NAME']
with open('$INSTALLED_PLUGINS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null && echo "✅ Removed from configuration" || echo "⚠️  Could not modify JSON file"
fi

# Remove plugin directory
if [ -n "$PLUGIN_PATH" ] && [ -d "$PLUGIN_PATH" ]; then
    echo "🗑️  Removing plugin directory: $PLUGIN_PATH"
    rm -rf "$PLUGIN_PATH"
    echo "✅ Removed plugin files"
elif [ -n "$PLUGIN_PATH" ]; then
    echo "⚠️  Plugin directory not found: $PLUGIN_PATH (already removed)"
else
    echo "⚠️  Could not determine plugin path"
fi

# Check if marketplace directory should be removed
MARKETPLACE_NAME=$(echo "$PLUGIN_NAME" | cut -d'@' -f2)
if [ -d "$MARKETPLACES_DIR/$MARKETPLACE_NAME" ]; then
    # Check if there are other plugins from this marketplace
    OTHER_PLUGINS=$(cat "$INSTALLED_PLUGINS_FILE" | grep -c "@$MARKETPLACE_NAME\"" || echo "0")
    if [ "$OTHER_PLUGINS" -eq 0 ]; then
        echo "🗑️  Removing empty marketplace directory: $MARKETPLACES_DIR/$MARKETPLACE_NAME"
        rm -rf "$MARKETPLACES_DIR/$MARKETPLACE_NAME"
        echo "✅ Removed marketplace directory"
    fi
fi

# Remove from settings.json enabledPlugins
if [ -f "$SETTINGS_FILE" ]; then
    python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    data = json.load(f)
if 'enabledPlugins' in data and '$PLUGIN_NAME' in data['enabledPlugins']:
    del data['enabledPlugins']['$PLUGIN_NAME']
    with open('$SETTINGS_FILE', 'w') as f:
        json.dump(data, f, indent=2)
    print('✅ Removed from settings.json')
" 2>/dev/null || true
fi

# Remove from settings.local.json enabledPlugins
if [ -f "$SETTINGS_LOCAL_FILE" ]; then
    python3 -c "
import json
with open('$SETTINGS_LOCAL_FILE', 'r') as f:
    data = json.load(f)
if 'enabledPlugins' in data and '$PLUGIN_NAME' in data['enabledPlugins']:
    del data['enabledPlugins']['$PLUGIN_NAME']
    with open('$SETTINGS_LOCAL_FILE', 'w') as f:
        json.dump(data, f, indent=2)
    print('✅ Removed from settings.local.json')
" 2>/dev/null || true
fi

echo ""
echo "✅ Plugin '$PLUGIN_NAME' removed successfully!"
echo "📦 Backup saved at: $BACKUP_DIR"
echo ""
echo "💡 Restart Claude Code to apply changes"
