#!/bin/bash
# VNC Plugin - VNC + WSS server

PLUGIN_NAME="vnc"
PLUGIN_VERSION="1.0.0"
PLUGIN_DEPS="tigervnc websockify openbox xorg-xsetroot"

vnc_plugin_install() {
    pkg install -y $PLUGIN_DEPS
    
    # Optional: Install noVNC for web access
    if [[ ! -d /usr/share/novnc ]]; then
        mkdir -p /usr/share/novnc
        curl -sL https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | \
            tar xz -C /usr/share/novnc --strip-components=1 || true
    fi
}

vnc_plugin_status() {
    echo "VNC plugin v$PLUGIN_VERSION"
    for dep in $PLUGIN_DEPS; do
        if command -v $dep &>/dev/null; then
            echo "  ✓ $dep"
        else
            echo "  ✗ $dep (missing)"
        fi
    done
    
    if pgrep -f "Xvnc" &>/dev/null; then
        echo "  VNC Server: Running"
    else
        echo "  VNC Server: Stopped"
    fi
}
