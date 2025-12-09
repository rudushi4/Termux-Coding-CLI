#!/data/data/com.termux/files/usr/bin/bash
#
# Termux-Coding-CLI Installer v2.0
# One-command setup with MCP + CUA support
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

TCC_HOME="$HOME/.tcc"
TCC_VERSION="2.0.0"
REPO_URL="https://raw.githubusercontent.com/rudushi4/Termux-Coding-CLI/main"

log() { echo -e "${GREEN}[TCC]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

banner() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════╗"
    echo "║     Termux-Coding-CLI v$TCC_VERSION          ║"
    echo "║   AI + MCP + CUA • Build Ship Preview  ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check environment
check_termux() {
    if [[ ! -d "/data/data/com.termux" ]]; then
        warn "Not running in Termux - some features may not work"
    fi
}

# Update packages
update_packages() {
    log "Updating package lists..."
    pkg update -y 2>/dev/null || apt-get update -y
    pkg upgrade -y 2>/dev/null || apt-get upgrade -y
}

# Install core dependencies
install_core() {
    log "Installing core packages..."
    pkg install -y \
        nodejs-lts \
        python \
        git \
        curl \
        wget \
        openssh \
        jq 2>/dev/null || {
        apt-get install -y nodejs npm python3 git curl wget openssh-client jq
    }
}

# Install VNC + WSS
install_vnc() {
    log "Installing VNC with WSS support..."
    pkg install -y \
        tigervnc \
        websockify \
        openbox \
        xorg-xsetroot 2>/dev/null || true
}

# Install Playwright dependencies
install_playwright() {
    log "Setting up Playwright for browser automation..."
    npm install -g playwright 2>/dev/null || true
    npx playwright install-deps 2>/dev/null || true
}

# Create directory structure
setup_directories() {
    log "Creating directory structure..."
    mkdir -p "$TCC_HOME"/{providers,plugins,vnc,logs,bin,mcp,cua}
    mkdir -p "$HOME/workspace"
}

# Download and install files
install_files() {
    log "Installing TCC files..."
    
    # Main CLI
    curl -fsSL "$REPO_URL/bin/tcc" -o "$TCC_HOME/bin/tcc"
    chmod +x "$TCC_HOME/bin/tcc"
    
    # MCP Manager
    curl -fsSL "$REPO_URL/mcp/mcp-manager.sh" -o "$TCC_HOME/mcp/mcp-manager.sh"
    curl -fsSL "$REPO_URL/mcp/mcp-config.json" -o "$TCC_HOME/mcp/mcp-config.json"
    
    # CUA Agent
    curl -fsSL "$REPO_URL/cua/cua-agent.sh" -o "$TCC_HOME/cua/cua-agent.sh"
    
    # Providers
    for provider in detect gemini openai deepseek mistral; do
        curl -fsSL "$REPO_URL/providers/${provider}.sh" -o "$TCC_HOME/providers/${provider}.sh" 2>/dev/null || true
    done
    
    # VNC
    curl -fsSL "$REPO_URL/vnc/vnc-wss.sh" -o "$TCC_HOME/vnc/vnc-wss.sh" 2>/dev/null || true
    
    # Plugins
    curl -fsSL "$REPO_URL/plugins/manager.sh" -o "$TCC_HOME/plugins/manager.sh" 2>/dev/null || true
}

# Create config if not exists
install_config() {
    if [[ ! -f "$TCC_HOME/config.sh" ]]; then
        log "Creating configuration..."
        cat > "$TCC_HOME/config.sh" << 'EOF'
#!/bin/bash
# TCC Configuration v2.0

# AI Provider: auto|claude|gemini|openai|deepseek|mistral
TCC_PROVIDER="auto"

# VNC Settings
TCC_VNC_PORT=5901
TCC_VNC_WSS_PORT=6080
TCC_VNC_RESOLUTION="1280x720"
TCC_VNC_DEPTH=24

# MCP Settings
TCC_MCP_AUTOSTART="playwright"

# CUA Settings
TCC_WORKSPACE="$HOME/workspace"

# Plugins
TCC_PLUGINS="core claude vnc"

# Logging
TCC_LOG_LEVEL="info"
EOF
    fi
}

# Create provider detection if not exists
install_providers() {
    if [[ ! -f "$TCC_HOME/providers/detect.sh" ]]; then
        log "Setting up AI provider detection..."
        cat > "$TCC_HOME/providers/detect.sh" << 'EOF'
#!/bin/bash
# AI Provider Auto-Detection

detect_provider() {
    export TCC_ACTIVE_PROVIDER=""
    
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
        echo "Active: $TCC_ACTIVE_PROVIDER"
    fi
}
EOF
    fi
    
    # Create provider modules
    for provider in gemini openai deepseek mistral; do
        [[ ! -f "$TCC_HOME/providers/${provider}.sh" ]] && {
            cat > "$TCC_HOME/providers/${provider}.sh" << EOF
#!/bin/bash
${provider}_chat() {
    local prompt="\$*"
    echo "Provider: $provider"
    echo "Prompt: \$prompt"
    echo "(Implement API call here)"
}
EOF
        }
    done
}

# Setup VNC with WSS
install_vnc_wss() {
    if [[ ! -f "$TCC_HOME/vnc/vnc-wss.sh" ]]; then
        log "Setting up VNC with WebSocket..."
        cat > "$TCC_HOME/vnc/vnc-wss.sh" << 'EOFVNC'
#!/bin/bash
VNC_PORT="${TCC_VNC_PORT:-5901}"
WSS_PORT="${TCC_VNC_WSS_PORT:-6080}"
VNC_RES="${TCC_VNC_RESOLUTION:-1280x720}"
VNC_DISPLAY=":1"
LOG_DIR="$HOME/.tcc/logs"

vnc_start() {
    vnc_stop 2>/dev/null
    mkdir -p ~/.vnc
    cat > ~/.vnc/xstartup << 'XEOF'
#!/bin/bash
exec openbox-session &
XEOF
    chmod +x ~/.vnc/xstartup
    vncserver $VNC_DISPLAY -geometry $VNC_RES -localhost no >> "$LOG_DIR/vnc.log" 2>&1
    if command -v websockify &>/dev/null; then
        websockify $WSS_PORT localhost:$VNC_PORT >> "$LOG_DIR/wss.log" 2>&1 &
        echo $! > "$LOG_DIR/wss.pid"
    fi
    sleep 2
    vnc_status
}

vnc_stop() {
    vncserver -kill $VNC_DISPLAY 2>/dev/null || true
    [[ -f "$LOG_DIR/wss.pid" ]] && kill $(cat "$LOG_DIR/wss.pid") 2>/dev/null
    rm -f "$LOG_DIR/wss.pid"
    echo "VNC stopped."
}

vnc_status() {
    echo "=== VNC Status ==="
    pgrep -f "Xvnc.*$VNC_DISPLAY" &>/dev/null && echo "VNC: ✓ Running on :$VNC_PORT" || echo "VNC: ✗ Stopped"
    pgrep -f "websockify.*$WSS_PORT" &>/dev/null && echo "WSS: ✓ Running on :$WSS_PORT" || echo "WSS: ✗ Stopped"
}
EOFVNC
        chmod +x "$TCC_HOME/vnc/vnc-wss.sh"
    fi
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

# Print completion
print_complete() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      Installation Complete! v$TCC_VERSION     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo "Quick Start:"
    echo ""
    echo "  # Set AI key"
    echo "  export ANTHROPIC_API_KEY=\"your-key\""
    echo ""
    echo "  # Use AI"
    echo "  tcc ai chat \"Hello\""
    echo ""
    echo "  # MCP servers"
    echo "  tcc mcp list"
    echo "  tcc mcp start playwright"
    echo "  tcc mcp add-remote myserver wss://example.com/mcp"
    echo ""
    echo "  # Build/Ship/Preview"
    echo "  tcc cua create react myapp"
    echo "  tcc cua build"
    echo "  tcc cua preview"
    echo "  tcc cua ship github"
    echo ""
    echo "  # VNC"
    echo "  tcc vnc start"
    echo ""
    echo -e "${YELLOW}Run: source ~/.bashrc${NC}"
}

# Main
main() {
    banner
    check_termux
    update_packages
    install_core
    setup_directories
    install_vnc
    install_playwright
    install_config
    install_providers
    install_vnc_wss
    install_files 2>/dev/null || true
    setup_path
    print_complete
}

main "$@"
