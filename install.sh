#!/data/data/com.termux/files/usr/bin/bash
#
# Termux-Coding-CLI Installer
# One-command setup for Claude Code + AI providers
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TCC_HOME="$HOME/.tcc"
TCC_VERSION="1.0.0"

log() { echo -e "${GREEN}[TCC]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

banner() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║     Termux-Coding-CLI Installer        ║"
    echo "║   Claude Code + AI Providers Setup     ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check environment
check_termux() {
    if [[ ! -d "/data/data/com.termux" ]]; then
        error "This script must run in Termux"
    fi
}

# Update packages
update_packages() {
    log "Updating package lists..."
    pkg update -y
    pkg upgrade -y
}

# Install core dependencies (~15MB)
install_core() {
    log "Installing core packages..."
    pkg install -y \
        nodejs-lts \
        python \
        git \
        curl \
        wget \
        openssh \
        jq
}

# Install VNC + WSS (~20MB)
install_vnc() {
    log "Installing VNC with WSS support..."
    pkg install -y \
        tigervnc \
        websockify \
        openbox \
        xorg-xsetroot
}

# Install Claude Code
install_claude() {
    log "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code 2>/dev/null || {
        warn "Claude Code npm install failed, setting up manually..."
    }
}

# Create directory structure
setup_directories() {
    log "Creating directory structure..."
    mkdir -p "$TCC_HOME"/{providers,plugins,vnc,logs,bin}
}

# Install main CLI
install_cli() {
    log "Installing TCC CLI..."
    
    cat > "$TCC_HOME/bin/tcc" << 'EOFCLI'
#!/data/data/com.termux/files/usr/bin/bash
#
# TCC - Termux Coding CLI
#

TCC_HOME="$HOME/.tcc"
source "$TCC_HOME/config.sh" 2>/dev/null || true
source "$TCC_HOME/providers/detect.sh" 2>/dev/null || true

show_help() {
    echo "Termux-Coding-CLI v1.0.0"
    echo ""
    echo "Usage: tcc <command> [options]"
    echo ""
    echo "Commands:"
    echo "  ai [chat] <prompt>   Use detected AI provider"
    echo "  vnc <start|stop|status>  Manage VNC server"
    echo "  plugin <list|install|remove> <name>  Manage plugins"
    echo "  config               Edit configuration"
    echo "  update               Update TCC"
    echo "  providers            List available AI providers"
    echo "  help                 Show this help"
}

cmd_ai() {
    detect_provider
    if [[ -z "$TCC_ACTIVE_PROVIDER" ]]; then
        echo "No AI provider detected. Set one of:"
        echo "  ANTHROPIC_API_KEY, GOOGLE_GENERATIVE_AI_API_KEY,"
        echo "  OPENAI_API_KEY, DEEPSEEK_API_KEY, MISTRAL_API_KEY"
        exit 1
    fi
    
    echo "Using provider: $TCC_ACTIVE_PROVIDER"
    
    case "$TCC_ACTIVE_PROVIDER" in
        claude)
            if command -v claude &>/dev/null; then
                claude "$@"
            else
                echo "Claude Code not installed. Run: npm i -g @anthropic-ai/claude-code"
            fi
            ;;
        gemini)
            source "$TCC_HOME/providers/gemini.sh"
            gemini_chat "$@"
            ;;
        openai)
            source "$TCC_HOME/providers/openai.sh"
            openai_chat "$@"
            ;;
        deepseek)
            source "$TCC_HOME/providers/deepseek.sh"
            deepseek_chat "$@"
            ;;
        mistral)
            source "$TCC_HOME/providers/mistral.sh"
            mistral_chat "$@"
            ;;
    esac
}

cmd_vnc() {
    source "$TCC_HOME/vnc/vnc-wss.sh"
    case "$1" in
        start) vnc_start ;;
        stop) vnc_stop ;;
        status) vnc_status ;;
        *) echo "Usage: tcc vnc <start|stop|status>" ;;
    esac
}

cmd_plugin() {
    source "$TCC_HOME/plugins/manager.sh"
    case "$1" in
        list) plugin_list ;;
        install) plugin_install "$2" ;;
        remove) plugin_remove "$2" ;;
        update) plugin_update ;;
        *) echo "Usage: tcc plugin <list|install|remove|update> [name]" ;;
    esac
}

cmd_providers() {
    source "$TCC_HOME/providers/detect.sh"
    list_providers
}

cmd_config() {
    ${EDITOR:-nano} "$TCC_HOME/config.sh"
}

cmd_update() {
    echo "Updating Termux-Coding-CLI..."
    cd "$HOME/Termux-Coding-CLI" 2>/dev/null && git pull || {
        echo "Reinstalling from remote..."
        curl -fsSL https://raw.githubusercontent.com/rudushi4/Termux-Coding-CLI/main/install.sh | bash
    }
}

# Main
case "$1" in
    ai) shift; cmd_ai "$@" ;;
    vnc) shift; cmd_vnc "$@" ;;
    plugin) shift; cmd_plugin "$@" ;;
    providers) cmd_providers ;;
    config) cmd_config ;;
    update) cmd_update ;;
    help|--help|-h|"" ) show_help ;;
    *) echo "Unknown command: $1"; show_help ;;
esac
EOFCLI

    chmod +x "$TCC_HOME/bin/tcc"
}

# Install config
install_config() {
    log "Creating configuration..."
    
    cat > "$TCC_HOME/config.sh" << 'EOF'
#!/bin/bash
# TCC Configuration

# Default AI provider: auto|claude|gemini|openai|deepseek|mistral
TCC_PROVIDER="auto"

# VNC Settings
TCC_VNC_PORT=5901
TCC_VNC_WSS_PORT=6080
TCC_VNC_RESOLUTION="1280x720"
TCC_VNC_DEPTH=24

# Plugins to auto-load
TCC_PLUGINS="core claude vnc"

# Logging
TCC_LOG_LEVEL="info"
EOF
}

# Install provider detection
install_providers() {
    log "Setting up AI provider detection..."
    
    # Main detection script
    cat > "$TCC_HOME/providers/detect.sh" << 'EOF'
#!/bin/bash
# AI Provider Auto-Detection

detect_provider() {
    export TCC_ACTIVE_PROVIDER=""
    
    # Check in priority order
    if [[ -n "$ANTHROPIC_API_KEY" ]]; then
        TCC_ACTIVE_PROVIDER="claude"
    elif [[ -n "$GOOGLE_GENERATIVE_AI_API_KEY" ]]; then
        TCC_ACTIVE_PROVIDER="gemini"
    elif [[ -n "$OPENAI_API_KEY" ]]; then
        TCC_ACTIVE_PROVIDER="openai"
    elif [[ -n "$DEEPSEEK_API_KEY" ]]; then
        TCC_ACTIVE_PROVIDER="deepseek"
    elif [[ -n "$MISTRAL_API_KEY" ]]; then
        TCC_ACTIVE_PROVIDER="mistral"
    fi
    
    # Override with config if set
    if [[ "$TCC_PROVIDER" != "auto" && -n "$TCC_PROVIDER" ]]; then
        TCC_ACTIVE_PROVIDER="$TCC_PROVIDER"
    fi
}

list_providers() {
    echo "Available AI Providers:"
    echo ""
    
    check_key() {
        if [[ -n "$1" ]]; then
            echo -e "  ✓ $2 (configured)"
        else
            echo -e "  ✗ $2 (not set)"
        fi
    }
    
    check_key "$ANTHROPIC_API_KEY" "Claude (ANTHROPIC_API_KEY)"
    check_key "$GOOGLE_GENERATIVE_AI_API_KEY" "Gemini (GOOGLE_GENERATIVE_AI_API_KEY)"
    check_key "$OPENAI_API_KEY" "OpenAI (OPENAI_API_KEY)"
    check_key "$DEEPSEEK_API_KEY" "DeepSeek (DEEPSEEK_API_KEY)"
    check_key "$MISTRAL_API_KEY" "Mistral (MISTRAL_API_KEY)"
    
    echo ""
    detect_provider
    if [[ -n "$TCC_ACTIVE_PROVIDER" ]]; then
        echo "Active provider: $TCC_ACTIVE_PROVIDER"
    else
        echo "No provider configured."
    fi
}
EOF

    # Gemini provider
    cat > "$TCC_HOME/providers/gemini.sh" << 'EOF'
#!/bin/bash
# Google Gemini Provider

gemini_chat() {
    local prompt="$*"
    local model="${GEMINI_MODEL:-gemini-pro}"
    
    curl -s "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GOOGLE_GENERATIVE_AI_API_KEY}" \
        -H 'Content-Type: application/json' \
        -d "{
            \"contents\": [{
                \"parts\": [{\"text\": \"$prompt\"}]
            }]
        }" | jq -r '.candidates[0].content.parts[0].text // .error.message'
}
EOF

    # OpenAI provider
    cat > "$TCC_HOME/providers/openai.sh" << 'EOF'
#!/bin/bash
# OpenAI Provider

openai_chat() {
    local prompt="$*"
    local model="${OPENAI_MODEL:-gpt-4o-mini}"
    
    curl -s "https://api.openai.com/v1/chat/completions" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H 'Content-Type: application/json' \
        -d "{
            \"model\": \"$model\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]
        }" | jq -r '.choices[0].message.content // .error.message'
}
EOF

    # DeepSeek provider
    cat > "$TCC_HOME/providers/deepseek.sh" << 'EOF'
#!/bin/bash
# DeepSeek Provider

deepseek_chat() {
    local prompt="$*"
    local model="${DEEPSEEK_MODEL:-deepseek-chat}"
    
    curl -s "https://api.deepseek.com/v1/chat/completions" \
        -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
        -H 'Content-Type: application/json' \
        -d "{
            \"model\": \"$model\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]
        }" | jq -r '.choices[0].message.content // .error.message'
}
EOF

    # Mistral provider
    cat > "$TCC_HOME/providers/mistral.sh" << 'EOF'
#!/bin/bash
# Mistral Provider

mistral_chat() {
    local prompt="$*"
    local model="${MISTRAL_MODEL:-mistral-small-latest}"
    
    curl -s "https://api.mistral.ai/v1/chat/completions" \
        -H "Authorization: Bearer $MISTRAL_API_KEY" \
        -H 'Content-Type: application/json' \
        -d "{
            \"model\": \"$model\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]
        }" | jq -r '.choices[0].message.content // .error.message'
}
EOF
}

# Install VNC with WSS
install_vnc_wss() {
    log "Setting up VNC with WebSocket..."
    
    cat > "$TCC_HOME/vnc/vnc-wss.sh" << 'EOF'
#!/bin/bash
# VNC Server with WSS Support

VNC_PORT="${TCC_VNC_PORT:-5901}"
WSS_PORT="${TCC_VNC_WSS_PORT:-6080}"
VNC_RES="${TCC_VNC_RESOLUTION:-1280x720}"
VNC_DEPTH="${TCC_VNC_DEPTH:-24}"
VNC_DISPLAY=":1"
LOG_DIR="$HOME/.tcc/logs"

vnc_start() {
    echo "Starting VNC server..."
    
    # Kill existing
    vnc_stop 2>/dev/null
    
    # Create xstartup
    mkdir -p ~/.vnc
    cat > ~/.vnc/xstartup << 'XEOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
exec openbox-session &
XEOF
    chmod +x ~/.vnc/xstartup
    
    # Start VNC
    vncserver $VNC_DISPLAY \
        -geometry $VNC_RES \
        -depth $VNC_DEPTH \
        -localhost no \
        >> "$LOG_DIR/vnc.log" 2>&1
    
    # Start WebSocket proxy for WSS
    if command -v websockify &>/dev/null; then
        echo "Starting WebSocket proxy on port $WSS_PORT..."
        websockify --web=/usr/share/novnc \
            $WSS_PORT localhost:$VNC_PORT \
            >> "$LOG_DIR/wss.log" 2>&1 &
        echo $! > "$LOG_DIR/wss.pid"
    fi
    
    sleep 2
    vnc_status
}

vnc_stop() {
    echo "Stopping VNC server..."
    vncserver -kill $VNC_DISPLAY 2>/dev/null || true
    
    # Stop WSS
    if [[ -f "$LOG_DIR/wss.pid" ]]; then
        kill $(cat "$LOG_DIR/wss.pid") 2>/dev/null || true
        rm -f "$LOG_DIR/wss.pid"
    fi
    
    pkill -f websockify 2>/dev/null || true
    echo "VNC stopped."
}

vnc_status() {
    echo ""
    echo "=== VNC Server Status ==="
    
    if pgrep -f "Xvnc.*$VNC_DISPLAY" &>/dev/null; then
        echo "VNC:  ✓ Running"
        echo "  └─ Port: $VNC_PORT"
        echo "  └─ Display: $VNC_DISPLAY"
        echo "  └─ Resolution: $VNC_RES"
    else
        echo "VNC:  ✗ Not running"
    fi
    
    if pgrep -f "websockify.*$WSS_PORT" &>/dev/null; then
        echo "WSS:  ✓ Running"
        echo "  └─ Port: $WSS_PORT"
        echo "  └─ URL: ws://localhost:$WSS_PORT"
    else
        echo "WSS:  ✗ Not running"
    fi
    
    echo ""
    echo "Connect via:"
    echo "  VNC Client: localhost:$VNC_PORT"
    echo "  Web Browser: http://localhost:$WSS_PORT/vnc.html"
}
EOF

    chmod +x "$TCC_HOME/vnc/vnc-wss.sh"
}

# Install plugin manager
install_plugin_manager() {
    log "Setting up plugin manager..."
    
    cat > "$TCC_HOME/plugins/manager.sh" << 'EOF'
#!/bin/bash
# TCC Plugin Manager

PLUGIN_DIR="$HOME/.tcc/plugins"
PLUGIN_REPO="https://raw.githubusercontent.com/rudushi4/Termux-Coding-CLI/main/plugins"

# Available plugins
declare -A PLUGINS=(
    [core]="Base CLI tools|5MB"
    [claude]="Claude Code integration|10MB"
    [vnc]="VNC + WSS server|15MB"
    [gui]="XFCE4 minimal desktop|20MB"
    [dev]="Dev tools (python, git)|15MB"
    [editors]="Nano, Vim, Micro|5MB"
)

plugin_list() {
    echo "Available Plugins:"
    echo ""
    printf "%-12s %-30s %s\n" "NAME" "DESCRIPTION" "SIZE"
    echo "─────────────────────────────────────────────────"
    
    for name in "${!PLUGINS[@]}"; do
        IFS='|' read -r desc size <<< "${PLUGINS[$name]}"
        status=""
        [[ -f "$PLUGIN_DIR/$name.sh" ]] && status=" [installed]"
        printf "%-12s %-30s %s%s\n" "$name" "$desc" "$size" "$status"
    done
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
            pkg install -y xfce4 xfce4-terminal
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
EOF

    chmod +x "$TCC_HOME/plugins/manager.sh"
    
    # Mark default plugins as installed
    touch "$TCC_HOME/plugins/core.sh"
    touch "$TCC_HOME/plugins/claude.sh"
}

# Setup PATH
setup_path() {
    log "Setting up PATH..."
    
    if ! grep -q "TCC_HOME" ~/.bashrc 2>/dev/null; then
        cat >> ~/.bashrc << 'EOF'

# Termux-Coding-CLI
export TCC_HOME="$HOME/.tcc"
export PATH="$TCC_HOME/bin:$PATH"
EOF
    fi
    
    export TCC_HOME="$HOME/.tcc"
    export PATH="$TCC_HOME/bin:$PATH"
}

# Print completion message
print_complete() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Installation Complete!               ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Quick Start:"
    echo "  1. Set your API key:"
    echo "     export ANTHROPIC_API_KEY=\"your-key\""
    echo ""
    echo "  2. Start using TCC:"
    echo "     tcc ai chat \"Hello\""
    echo "     tcc vnc start"
    echo "     tcc providers"
    echo ""
    echo "  3. View help:"
    echo "     tcc help"
    echo ""
    echo -e "${YELLOW}Run 'source ~/.bashrc' or restart Termux${NC}"
}

# Main installation
main() {
    banner
    check_termux
    update_packages
    install_core
    setup_directories
    install_cli
    install_config
    install_providers
    install_vnc
    install_vnc_wss
    install_plugin_manager
    install_claude
    setup_path
    print_complete
}

main "$@"
