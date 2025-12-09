# 🚀 Termux-Coding-CLI

**Claude Code + AI + MCP + CUA on Android** - Universal coding agent for Termux

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Termux](https://img.shields.io/badge/Termux-Compatible-green.svg)](https://termux.dev)
[![MCP](https://img.shields.io/badge/MCP-Supported-purple.svg)](https://modelcontextprotocol.io)

## ✨ Features

- 🔌 **Universal MCP Support** - Any local or remote MCP server
- 🤖 **AI Providers** - Claude, Gemini, OpenAI, DeepSeek, Mistral
- 🖥️ **VNC + WSS** - Secure desktop access
- 🚀 **CUA Agent** - Build, Ship, Preview anything
- 🎭 **Playwright** - Browser automation built-in
- 📦 **~30MB Minimal** - Lightweight and fast

## ⚡ Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/rudushi4/Termux-Coding-CLI/main/install.sh | bash
```

## 🔌 MCP Server Support

### Built-in MCP Servers

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

### Manage MCP Servers

```bash
# List all servers
tcc mcp list

# Start Playwright MCP
tcc mcp start playwright

# Add custom MCP server
tcc mcp add myserver npx @my/mcp-package

# Add remote MCP server (WSS)
tcc mcp add-remote production wss://mcp.myserver.com/ws my-token

# Start all servers
tcc mcp start-all

# Edit config directly
tcc mcp config edit

# Export for Claude Code
tcc mcp export ~/.claude/mcp_config.json
```

### Remote MCP Servers

```bash
# Add remote server with token
tcc mcp add-remote myremote wss://api.example.com/mcp secret-token

# Add remote server without token
tcc mcp add-remote public-mcp wss://public.mcp-server.io/ws
```

## 🤖 CUA - Computer Use Agent

### Build Projects

```bash
# Auto-detect and build
tcc cua build

# Build specific project
tcc cua build ./myproject node
```

### Ship/Deploy

```bash
# Deploy to GitHub
tcc cua ship github

# Deploy to Surge
tcc cua ship surge

# Deploy to Vercel
tcc cua ship vercel

# Deploy to Netlify
tcc cua ship netlify
```

### Preview

```bash
# Start preview server
tcc cua preview

# Custom port
tcc cua preview . 3000

# Stop preview
tcc cua preview-stop
```

### Create Projects

```bash
tcc cua create react myapp
tcc cua create vue myapp
tcc cua create node myapi
tcc cua create python myproject
tcc cua create html mysite
```

### Browser Automation

```bash
# Take screenshot
tcc cua browser screenshot https://example.com shot.png

# Generate PDF
tcc cua browser pdf https://example.com doc.pdf

# Run custom Playwright script
tcc cua browser run myscript.js
```

## 🔑 AI Providers

```bash
# Auto-detection from environment
export ANTHROPIC_API_KEY="sk-..."          # Claude
export GOOGLE_GENERATIVE_AI_API_KEY="..."  # Gemini
export OPENAI_API_KEY="sk-..."             # OpenAI
export DEEPSEEK_API_KEY="..."              # DeepSeek
export MISTRAL_API_KEY="..."               # Mistral

# Use AI
tcc ai chat "Explain MCP protocol"

# Check providers
tcc providers
```

## 🖥️ VNC Server

```bash
# Set password
vncpasswd

# Start VNC + WebSocket
tcc vnc start

# Check status
tcc vnc status

# Connect:
# VNC: localhost:5901
# WSS: ws://localhost:6080
```

## 📁 Configuration

### Main Config: `~/.tcc/config.sh`

```bash
# AI Provider
TCC_PROVIDER="auto"

# VNC Settings
TCC_VNC_PORT=5901
TCC_VNC_WSS_PORT=6080
TCC_VNC_RESOLUTION="1280x720"

# MCP auto-start servers
TCC_MCP_AUTOSTART="playwright"

# Workspace
TCC_WORKSPACE="$HOME/workspace"
```

### MCP Config: `~/.tcc/mcp/mcp-config.json`

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-filesystem", "/workspace"]
    }
  },
  "remoteMcpServers": {
    "production": {
      "url": "wss://mcp.mycompany.com/ws",
      "token": "secret-token"
    }
  }
}
```

## 📋 All Commands

```bash
# AI
tcc ai chat "prompt"     # Chat with AI
tcc providers            # List providers

# MCP
tcc mcp list             # List servers
tcc mcp start <name>     # Start server
tcc mcp stop <name>      # Stop server
tcc mcp add <n> <cmd>    # Add local server
tcc mcp add-remote <n> <url> [token]  # Add remote
tcc mcp remove <name>    # Remove server
tcc mcp config           # Show config
tcc mcp config edit      # Edit config
tcc mcp start-all        # Start all
tcc mcp stop-all         # Stop all

# CUA
tcc cua build            # Build project
tcc cua ship <target>    # Deploy
tcc cua preview          # Start server
tcc cua preview-stop     # Stop server
tcc cua create <t> <n>   # Create project
tcc cua browser <action> # Browser automation

# VNC
tcc vnc start            # Start VNC+WSS
tcc vnc stop             # Stop VNC
tcc vnc status           # Show status

# Plugins
tcc plugin list          # List plugins
tcc plugin install <n>   # Install plugin

# Other
tcc config               # Edit config
tcc update               # Update TCC
tcc help                 # Show help
```

## 🔧 Requirements

- Android 7.0+ / Linux
- Termux (F-Droid recommended)
- Node.js 18+
- ~30MB storage

## 📜 License

MIT License

---

**Made with ❤️ for mobile developers**
