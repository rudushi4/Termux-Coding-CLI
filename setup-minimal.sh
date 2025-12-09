#!/data/data/com.termux/files/usr/bin/bash
#
# Termux-Coding-CLI Minimal Setup
# Uses termux-desktop minimalist style (~30MB total)
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[TCC]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

banner() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════╗"
    echo "║   Termux-Coding-CLI Minimal Setup      ║"
    echo "║   ~30MB • VNC+WSS • AI Providers       ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check Termux
check_env() {
    if [[ ! -d "/data/data/com.termux" ]]; then
        echo "Error: Run this in Termux"
        exit 1
    fi
}

# Minimal packages (~30MB total)
install_minimal() {
    log "Installing minimal packages..."
    pkg update -y
    
    # Core (~10MB)
    pkg install -y nodejs-lts python git curl jq openssh
    
    # VNC minimal (~15MB)
    pkg install -y tigervnc websockify openbox xorg-xsetroot
    
    # Optional: minimal file manager (~5MB)
    pkg install -y pcmanfm 2>/dev/null || true
}

# Minimal desktop config
setup_desktop() {
    log "Setting up minimal desktop..."
    
    mkdir -p ~/.vnc ~/.config/openbox
    
    # VNC startup - openbox only (minimal)
    cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
export XDG_SESSION_TYPE=x11
xsetroot -solid "#0d0d14"
exec openbox-session
EOF
    chmod +x ~/.vnc/xstartup
    
    # Openbox minimal config
    cat > ~/.config/openbox/rc.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>Clearlooks</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
  </theme>
  <desktops>
    <number>1</number>
  </desktops>
  <keyboard>
    <keybind key="A-Tab">
      <action name="NextWindow"/>
    </keybind>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
  </keyboard>
  <mouse>
    <context name="Frame">
      <mousebind button="A-Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
      </mousebind>
      <mousebind button="A-Left" action="Drag">
        <action name="Move"/>
      </mousebind>
    </context>
  </mouse>
  <applications>
    <application class="*">
      <decor>yes</decor>
    </application>
  </applications>
</openbox_config>
EOF

    # Openbox menu (right-click)
    cat > ~/.config/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="Menu">
    <item label="Terminal">
      <action name="Execute"><command>xterm</command></action>
    </item>
    <item label="File Manager">
      <action name="Execute"><command>pcmanfm</command></action>
    </item>
    <separator/>
    <item label="Reconfigure">
      <action name="Reconfigure"/>
    </item>
    <item label="Exit">
      <action name="Exit"/>
    </item>
  </menu>
</openbox_menu>
EOF
}

# Run main install script
run_main_install() {
    log "Running main TCC install..."
    
    # Get install script
    if [[ -f "./install.sh" ]]; then
        bash ./install.sh
    else
        curl -fsSL https://raw.githubusercontent.com/rudushi4/Termux-Coding-CLI/main/install.sh | bash
    fi
}

# Quick start guide
print_done() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}   Minimal Setup Complete! (~30MB)      ${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo "Quick Start:"
    echo ""
    echo "  1. Set VNC password:"
    echo "     vncpasswd"
    echo ""
    echo "  2. Start VNC + WSS:"
    echo "     tcc vnc start"
    echo ""
    echo "  3. Connect:"
    echo "     VNC: localhost:5901"
    echo "     WSS: ws://localhost:6080"
    echo ""
    echo "  4. Set AI key:"
    echo "     export ANTHROPIC_API_KEY=\"your-key\""
    echo "     tcc ai chat \"Hello\""
    echo ""
    echo -e "${YELLOW}Restart Termux or run: source ~/.bashrc${NC}"
}

main() {
    banner
    check_env
    install_minimal
    setup_desktop
    run_main_install
    print_done
}

main "$@"
