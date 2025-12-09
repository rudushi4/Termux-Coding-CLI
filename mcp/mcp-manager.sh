#!/bin/bash
#
# MCP Manager - Universal MCP Server Support
# Supports local, remote, and custom MCP servers
#

MCP_DIR="$HOME/.tcc/mcp"
MCP_CONFIG="$MCP_DIR/mcp-config.json"
MCP_PIDS="$MCP_DIR/pids"
MCP_LOGS="$MCP_DIR/logs"

mkdir -p "$MCP_DIR" "$MCP_PIDS" "$MCP_LOGS"

# Initialize default config if not exists
mcp_init() {
    if [[ ! -f "$MCP_CONFIG" ]]; then
        cat > "$MCP_CONFIG" << 'EOF'
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  },
  "remoteMcpServers": {},
  "settings": {
    "autoConnect": true,
    "timeout": 30000
  }
}
EOF
        echo "Created default MCP config: $MCP_CONFIG"
    fi
}

# List all configured MCP servers
mcp_list() {
    echo "=== MCP Servers ==="
    echo ""
    
    if command -v jq &>/dev/null && [[ -f "$MCP_CONFIG" ]]; then
        echo "Local Servers:"
        jq -r '.mcpServers | keys[]' "$MCP_CONFIG" 2>/dev/null | while read name; do
            pid_file="$MCP_PIDS/$name.pid"
            if [[ -f "$pid_file" ]] && kill -0 $(cat "$pid_file") 2>/dev/null; then
                echo "  ✓ $name (running)"
            else
                echo "  ○ $name (stopped)"
            fi
        done
        
        echo ""
        echo "Remote Servers:"
        jq -r '.remoteMcpServers | keys[]' "$MCP_CONFIG" 2>/dev/null | while read name; do
            echo "  ◉ $name (remote)"
        done
    else
        echo "No MCP config found. Run: tcc mcp init"
    fi
}

# Start a specific MCP server
mcp_start() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: tcc mcp start <server-name>"; return 1; }
    
    mcp_init
    
    local cmd=$(jq -r ".mcpServers.\"$name\".command // empty" "$MCP_CONFIG")
    local args=$(jq -r ".mcpServers.\"$name\".args | @sh" "$MCP_CONFIG" | tr -d "'")
    
    if [[ -z "$cmd" ]]; then
        echo "Server '$name' not found in config"
        return 1
    fi
    
    echo "Starting MCP server: $name"
    
    # Export any environment variables
    eval $(jq -r ".mcpServers.\"$name\".env // {} | to_entries | .[] | \"export \(.key)=\(.value)\"" "$MCP_CONFIG" 2>/dev/null)
    
    # Start server in background
    nohup $cmd $args > "$MCP_LOGS/$name.log" 2>&1 &
    echo $! > "$MCP_PIDS/$name.pid"
    
    sleep 2
    if kill -0 $(cat "$MCP_PIDS/$name.pid") 2>/dev/null; then
        echo "✓ $name started (PID: $(cat "$MCP_PIDS/$name.pid"))"
    else
        echo "✗ Failed to start $name. Check: $MCP_LOGS/$name.log"
    fi
}

# Stop a specific MCP server
mcp_stop() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: tcc mcp stop <server-name>"; return 1; }
    
    local pid_file="$MCP_PIDS/$name.pid"
    if [[ -f "$pid_file" ]]; then
        kill $(cat "$pid_file") 2>/dev/null
        rm -f "$pid_file"
        echo "Stopped: $name"
    else
        echo "Server '$name' not running"
    fi
}

# Start all MCP servers
mcp_start_all() {
    mcp_init
    jq -r '.mcpServers | keys[]' "$MCP_CONFIG" 2>/dev/null | while read name; do
        mcp_start "$name"
    done
}

# Stop all MCP servers
mcp_stop_all() {
    for pid_file in "$MCP_PIDS"/*.pid; do
        [[ -f "$pid_file" ]] && {
            name=$(basename "$pid_file" .pid)
            mcp_stop "$name"
        }
    done
}

# Add a new MCP server
mcp_add() {
    local name="$1"
    local command="$2"
    shift 2
    local args="$@"
    
    [[ -z "$name" || -z "$command" ]] && {
        echo "Usage: tcc mcp add <name> <command> [args...]"
        echo "Example: tcc mcp add myserver npx @my/mcp-server"
        return 1
    }
    
    mcp_init
    
    # Convert args to JSON array
    local args_json=$(printf '%s\n' $args | jq -R . | jq -s .)
    
    # Add to config
    local tmp=$(mktemp)
    jq ".mcpServers.\"$name\" = {\"command\": \"$command\", \"args\": $args_json}" "$MCP_CONFIG" > "$tmp"
    mv "$tmp" "$MCP_CONFIG"
    
    echo "Added MCP server: $name"
}

# Add remote MCP server
mcp_add_remote() {
    local name="$1"
    local url="$2"
    local token="$3"
    
    [[ -z "$name" || -z "$url" ]] && {
        echo "Usage: tcc mcp add-remote <name> <url> [token]"
        echo "Example: tcc mcp add-remote myremote wss://mcp.example.com/ws my-token"
        return 1
    }
    
    mcp_init
    
    local tmp=$(mktemp)
    if [[ -n "$token" ]]; then
        jq ".remoteMcpServers.\"$name\" = {\"url\": \"$url\", \"token\": \"$token\"}" "$MCP_CONFIG" > "$tmp"
    else
        jq ".remoteMcpServers.\"$name\" = {\"url\": \"$url\"}" "$MCP_CONFIG" > "$tmp"
    fi
    mv "$tmp" "$MCP_CONFIG"
    
    echo "Added remote MCP server: $name -> $url"
}

# Remove MCP server
mcp_remove() {
    local name="$1"
    [[ -z "$name" ]] && { echo "Usage: tcc mcp remove <name>"; return 1; }
    
    mcp_stop "$name" 2>/dev/null
    
    local tmp=$(mktemp)
    jq "del(.mcpServers.\"$name\") | del(.remoteMcpServers.\"$name\")" "$MCP_CONFIG" > "$tmp"
    mv "$tmp" "$MCP_CONFIG"
    
    echo "Removed: $name"
}

# Show MCP config
mcp_config() {
    mcp_init
    
    if [[ "$1" == "edit" ]]; then
        ${EDITOR:-nano} "$MCP_CONFIG"
    else
        cat "$MCP_CONFIG" | jq .
    fi
}

# Install common MCP servers
mcp_install_common() {
    echo "Installing common MCP servers..."
    
    # Playwright for browser automation
    mcp_add playwright npx @playwright/mcp@latest
    
    # Filesystem access
    mcp_add filesystem npx -y @anthropic-ai/mcp-filesystem /data/data/com.termux/files/home
    
    # HTTP fetch
    mcp_add fetch npx -y @anthropic-ai/mcp-fetch
    
    echo "Done! Run 'tcc mcp list' to see servers."
}

# Export config for Claude Code
mcp_export() {
    local output="${1:-$HOME/.claude/mcp_config.json}"
    mkdir -p "$(dirname "$output")"
    cp "$MCP_CONFIG" "$output"
    echo "Exported to: $output"
}

# Main handler
mcp_main() {
    case "$1" in
        init) mcp_init ;;
        list|ls) mcp_list ;;
        start) mcp_start "$2" ;;
        stop) mcp_stop "$2" ;;
        start-all) mcp_start_all ;;
        stop-all) mcp_stop_all ;;
        add) shift; mcp_add "$@" ;;
        add-remote) shift; mcp_add_remote "$@" ;;
        remove|rm) mcp_remove "$2" ;;
        config) mcp_config "$2" ;;
        install-common) mcp_install_common ;;
        export) mcp_export "$2" ;;
        *)
            echo "MCP Manager - Universal MCP Server Support"
            echo ""
            echo "Usage: tcc mcp <command>"
            echo ""
            echo "Commands:"
            echo "  init              Initialize MCP config"
            echo "  list              List all MCP servers"
            echo "  start <name>      Start a server"
            echo "  stop <name>       Stop a server"
            echo "  start-all         Start all servers"
            echo "  stop-all          Stop all servers"
            echo "  add <name> <cmd> [args]    Add local server"
            echo "  add-remote <name> <url> [token]  Add remote server"
            echo "  remove <name>     Remove a server"
            echo "  config [edit]     Show/edit config"
            echo "  install-common    Install common MCP servers"
            echo "  export [path]     Export config for Claude Code"
            ;;
    esac
}
