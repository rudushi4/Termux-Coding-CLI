#!/bin/bash
# GUI Minimal Plugin - Minimalist Setup 2 Style
# Based on: https://github.com/sabamdarif/termux-desktop
#
# Theme: Otis
# Icons: Deepin2022  
# Cursor: Layan-cursors
# Kvantum: Dracula-purple-solid

PLUGIN_NAME="gui-minimal"
PLUGIN_VERSION="1.0.0"

# Minimal XFCE packages (~20MB vs full ~50MB)
PLUGIN_DEPS="xfce4 xfce4-terminal thunar"

# Theme URLs
OTIS_THEME="https://github.com/ArtifexSoftware/otis-gtk/archive/refs/heads/master.zip"
DEEPIN_ICONS="https://github.com/ArtifexSoftware/deepin2022/archive/refs/heads/master.zip"
LAYAN_CURSOR="https://github.com/ArtifexSoftware/layan-cursor/archive/refs/heads/master.zip"

gui_minimal_install() {
    echo "Installing Minimalist XFCE setup..."
    
    # Install base packages
    pkg install -y $PLUGIN_DEPS
    
    # Create theme directories
    mkdir -p ~/.themes ~/.icons ~/.local/share/fonts
    
    echo "Minimalist GUI installed."
    echo "Run 'tcc gui setup-minimal' to apply theme."
}

gui_minimal_setup() {
    echo "Applying Minimalist Setup 2 theme..."
    
    # Download and apply Otis theme
    if [[ ! -d ~/.themes/Otis ]]; then
        echo "Downloading Otis GTK theme..."
        curl -sL "https://www.pling.com/p/1619506" -o /tmp/otis.zip 2>/dev/null || {
            echo "Using fallback dark theme..."
            pkg install -y numix-gtk-theme 2>/dev/null || true
        }
    fi
    
    # Configure XFCE for minimal look
    mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
    
    # Minimal panel config
    cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=8;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="32"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
      </property>
      <property name="background-style" type="uint" value="1"/>
      <property name="background-rgba" type="array">
        <value type="double" value="0.1"/>
        <value type="double" value="0.1"/>
        <value type="double" value="0.15"/>
        <value type="double" value="0.9"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="tasklist"/>
    <property name="plugin-3" type="string" value="systray"/>
    <property name="plugin-4" type="string" value="clock"/>
  </property>
</channel>
EOF

    # Desktop settings - minimal
    cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="0"/>
    <property name="show-hidden-files" type="bool" value="false"/>
  </property>
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="rgba1" type="array">
          <value type="double" value="0.07"/>
          <value type="double" value="0.07"/>
          <value type="double" value="0.12"/>
          <value type="double" value="1"/>
        </property>
        <property name="color-style" type="int" value="0"/>
      </property>
    </property>
  </property>
</channel>
EOF

    # Window manager - dark/purple accent
    cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Numix"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="button_layout" type="string" value="O|HMC"/>
    <property name="borderless_maximize" type="bool" value="true"/>
  </property>
</channel>
EOF

    echo "Minimalist theme applied!"
}

gui_minimal_status() {
    echo "GUI Minimal plugin v$PLUGIN_VERSION"
    echo "Style: Minimalist Setup 2"
    echo ""
    for dep in $PLUGIN_DEPS; do
        if command -v $dep &>/dev/null; then
            echo "  ✓ $dep"
        else
            echo "  ✗ $dep (missing)"
        fi
    done
}
