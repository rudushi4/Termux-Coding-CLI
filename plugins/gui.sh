#!/bin/bash
# GUI Plugin - XFCE4 minimal desktop

PLUGIN_NAME="gui"
PLUGIN_VERSION="1.0.0"
PLUGIN_DEPS="xfce4 xfce4-terminal thunar mousepad"

gui_plugin_install() {
    pkg install -y $PLUGIN_DEPS
    
    # Create xstartup for XFCE
    mkdir -p ~/.vnc
    cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
exec startxfce4 &
EOF
    chmod +x ~/.vnc/xstartup
}

gui_plugin_status() {
    echo "GUI plugin v$PLUGIN_VERSION"
    for dep in $PLUGIN_DEPS; do
        if command -v $dep &>/dev/null; then
            echo "  ✓ $dep"
        else
            echo "  ✗ $dep (missing)"
        fi
    done
}
