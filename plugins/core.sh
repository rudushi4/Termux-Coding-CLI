#!/bin/bash
# Core Plugin - Base CLI tools
# Auto-installed with TCC

PLUGIN_NAME="core"
PLUGIN_VERSION="1.0.0"
PLUGIN_DEPS="curl wget jq git"

core_install() {
    pkg install -y $PLUGIN_DEPS
}

core_status() {
    echo "Core plugin v$PLUGIN_VERSION"
    for dep in $PLUGIN_DEPS; do
        if command -v $dep &>/dev/null; then
            echo "  ✓ $dep"
        else
            echo "  ✗ $dep (missing)"
        fi
    done
}
