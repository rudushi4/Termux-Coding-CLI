# 🚀 Termux-Coding-CLI

**Claude Code + AI Providers on Android** - One-command installer

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Termux](https://img.shields.io/badge/Termux-Compatible-green.svg)](https://termux.dev)

## ✨ Features

- 🔌 **Pluggable AI Providers** - Auto-detect Gemini, OpenAI, DeepSeek, Mistral, Claude
- 🖥️ **VNC + WSS Server** - Secure WebSocket access to GUI
- 📦 **~30MB Minimal** / ~50MB Full - Choose your setup
- 🛠️ **Plugin System** - Extend with custom modules
- 📱 **Termux Native** - No root required

## ⚡ Quick Install

### Minimal Setup (~30MB) - Recommended
```bash
curl -fsSL https://raw.githubusercontent.com/rudushi4/Termux-Coding-CLI/main/setup-minimal.sh | bash
```

### Full Setup (~50MB)
```bash
curl -fsSL https://raw.githubusercontent.com/rudushi4/Termux-Coding-CLI/main/install.sh | bash
```

## 🔑 API Keys Setup

Set your preferred AI provider:

```bash
# Claude (Anthropic)
export ANTHROPIC_API_KEY="your-key"

# Google Gemini
export GOOGLE_GENERATIVE_AI_API_KEY="your-key"

# OpenAI
export OPENAI_API_KEY="your-key"

# DeepSeek
export DEEPSEEK_API_KEY="your-key"

# Mistral/Codestral
export MISTRAL_API_KEY="your-key"
```

Add to `~/.bashrc` for persistence:
```bash
echo 'export ANTHROPIC_API_KEY="your-key"' >> ~/.bashrc
```

## 🖥️ VNC Server (with WSS)

```bash
# Set password first
vncpasswd

# Start VNC with WebSocket Secure
tcc vnc start

# Stop VNC
tcc vnc stop

# Get connection info
tcc vnc status
```

Connect via:
- **VNC Client**: `localhost:5901`
- **WebSocket**: `ws://localhost:6080`

## 🔌 Plugin System

### Available Plugins

| Plugin | Description | Size |
|--------|-------------|------|
| `core` | Base CLI tools | ~5MB |
| `claude` | Claude Code integration | ~10MB |
| `vnc` | VNC + WSS server | ~15MB |
| `gui-minimal` | Openbox minimal desktop | ~15MB |
| `gui` | XFCE4 full desktop | ~50MB |
| `dev` | Dev tools (git, python) | ~15MB |

### Manage Plugins

```bash
# List plugins
tcc plugin list

# Install minimal GUI
tcc plugin install gui-minimal

# Install full XFCE
tcc plugin install gui

# Remove plugin
tcc plugin remove gui
```

## 🛠️ Commands

```bash
tcc                    # Main CLI
tcc ai                 # Detect & use AI provider
tcc ai chat "prompt"   # Quick AI query
tcc vnc start          # Start VNC/WSS
tcc plugin <cmd>       # Plugin management
tcc providers          # List AI providers
tcc config             # Edit configuration
tcc update             # Update TCC
```

## 📁 Structure

```
~/.tcc/
├── config.sh          # Main configuration
├── providers/         # AI provider modules
├── plugins/           # Installed plugins
├── vnc/               # VNC configuration
└── logs/              # Runtime logs
```

## 🎨 Desktop Styles

Based on [termux-desktop](https://github.com/sabamdarif/termux-desktop) Minimalist Setup 2:

- **Theme**: Otis GTK
- **Icons**: Deepin2022
- **Cursor**: Layan
- **WM**: Openbox (minimal) or XFCE4 (full)

## 🔧 Configuration

Edit `~/.tcc/config.sh`:

```bash
# Default AI provider (auto|claude|gemini|openai|deepseek|mistral)
TCC_PROVIDER="auto"

# VNC settings
TCC_VNC_PORT=5901
TCC_VNC_WSS_PORT=6080
TCC_VNC_RESOLUTION="1280x720"

# Plugins to auto-load
TCC_PLUGINS="core claude vnc"
```

## 📋 Requirements

- Android 7.0+
- Termux (F-Droid version recommended)
- ~30MB storage (minimal) / ~50MB (full)
- Internet connection for AI APIs

## 🤝 Contributing

PRs welcome! See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📜 License

MIT License - see [LICENSE](LICENSE)

---

**Made with ❤️ for mobile developers**
