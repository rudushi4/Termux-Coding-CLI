#!/bin/bash
# TCC Plugin Manager

PLUGIN_DIR="$HOME/.tcc/plugins"
PLUGIN_REPO="https://raw.githubusercontent.com/rudushi4/Termux-Coding-CLI/main/plugins"

# Available plugins
declare -A PLUGINS=(
    [core]="Base CLI tools|5MB"
    [claude]="Claude Code integration|10MB"
    [vnc]="VNC + WSS server|15MB"
    [gui]="XFCE4 full desktop|50MB"
    [gui-minimal]="Openbox minimal desktop|15MB"
    [dev]="Dev tools (python, git)|15MB"
    [editors]="Nano, Vim, Micro|5MB"
)

plugin_list() {
    echo "Available Plugins:"
    echo ""
    printf "%-14s %-32s %s\n" "NAME" "DESCRIPTION" "SIZE"
    echo "─────────────────────────────────────────────────────────"
    
    for name in "${!PLUGINS[@]}"; do
        IFS='|' read -r desc size <<< "${PLUGINS[$name]}"
        status=""
        [[ -f "$PLUGIN_DIR/$name.sh" ]] && status=" [installed]"
        printf "%-14s %-32s %s%s\n" "$name" "$desc" "$size" "$status"
    done | sort
}

plugin_install() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: tcc plugin install <name>"; return 1; }
    
    if [[ -z "${PLUGINS[$name]}" ]]; then
        echo "Unknown plugin: $name"
        plugin_list
        return 1
    fi
    
    echo "Installing plugin: $name"
    
    case "$name" in
        core)
            pkg install -y curl wget jq git
            ;;
        claude)
            npm install -g @anthropic-ai/claude-code || echo "Manual setup may be required"
            ;;
        vnc)
            pkg install -y tigervnc websockify openbox xorg-xsetroot
            ;;
        gui)
            pkg install -y xfce4 xfce4-terminal thunar mousepad
            ;;
        gui-minimal)
            pkg install -y tigervnc websockify openbox xorg-xsetroot pcmanfm xterm
            source "$PLUGIN_DIR/gui-minimal.sh" 2>/dev/null
            gui_minimal_setup 2>/dev/null || true
            ;;
        dev)
            pkg install -y python nodejs-lts git openssh
            ;;
        editors)
            pkg install -y nano vim micro
            ;;
    esac
    
    touch "$PLUGIN_DIR/$name.sh"
    echo "Plugin '$name' installed."
}

plugin_remove() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: tcc plugin remove <name>"; return 1; }
    
    if [[ -f "$PLUGIN_DIR/$name.sh" ]]; then
        rm -f "$PLUGIN_DIR/$name.sh"
        echo "Plugin '$name' removed. Note: Packages not uninstalled."
    else
        echo "Plugin '$name' not installed."
    fi
}

plugin_update() {
    echo "Updating all plugins..."
    for plugin in "$PLUGIN_DIR"/*.sh; do
        [[ -f "$plugin" ]] && {
            name=$(basename "$plugin" .sh)
            plugin_install "$name"
        }
    done
    echo "All plugins updated."
}
