#!/bin/bash
#
# CUA - Computer Use Agent
# Advanced automation for build, ship, preview
#

CUA_DIR="$HOME/.tcc/cua"
CUA_WORKSPACE="$HOME/workspace"
CUA_LOGS="$CUA_DIR/logs"

mkdir -p "$CUA_DIR" "$CUA_WORKSPACE" "$CUA_LOGS"

# ============================================
# BUILD Functions
# ============================================

cua_build() {
    local project="$1"
    local type="${2:-auto}"
    
    [[ -z "$project" ]] && project="."
    cd "$project" 2>/dev/null || { echo "Project not found: $project"; return 1; }
    
    echo "🔨 Building project: $(pwd)"
    
    # Auto-detect project type
    if [[ "$type" == "auto" ]]; then
        if [[ -f "package.json" ]]; then
            type="node"
        elif [[ -f "requirements.txt" ]] || [[ -f "setup.py" ]]; then
            type="python"
        elif [[ -f "Cargo.toml" ]]; then
            type="rust"
        elif [[ -f "go.mod" ]]; then
            type="go"
        elif [[ -f "Makefile" ]]; then
            type="make"
        else
            type="unknown"
        fi
    fi
    
    echo "Detected: $type"
    
    case "$type" in
        node|npm)
            npm install && npm run build
            ;;
        python|pip)
            pip install -r requirements.txt 2>/dev/null
            python setup.py build 2>/dev/null || python -m build 2>/dev/null || echo "No build step needed"
            ;;
        rust)
            cargo build --release
            ;;
        go)
            go build ./...
            ;;
        make)
            make
            ;;
        *)
            echo "Unknown project type. Trying common build commands..."
            [[ -f "package.json" ]] && npm run build
            [[ -f "Makefile" ]] && make
            ;;
    esac
    
    echo "✅ Build complete"
}

# ============================================
# SHIP Functions
# ============================================

cua_ship() {
    local target="$1"
    local project="${2:-.}"
    
    echo "🚀 Shipping to: $target"
    
    cd "$project" 2>/dev/null || { echo "Project not found"; return 1; }
    
    case "$target" in
        github)
            cua_ship_github
            ;;
        npm)
            cua_ship_npm
            ;;
        docker)
            cua_ship_docker
            ;;
        surge)
            cua_ship_surge
            ;;
        netlify)
            cua_ship_netlify
            ;;
        vercel)
            cua_ship_vercel
            ;;
        *)
            echo "Targets: github, npm, docker, surge, netlify, vercel"
            ;;
    esac
}

cua_ship_github() {
    git add -A
    git commit -m "Ship: $(date '+%Y-%m-%d %H:%M')" 2>/dev/null || echo "Nothing to commit"
    git push origin $(git branch --show-current)
    echo "✅ Pushed to GitHub"
}

cua_ship_npm() {
    npm publish
}

cua_ship_docker() {
    local image="${1:-$(basename $(pwd))}:latest"
    docker build -t "$image" .
    docker push "$image"
}

cua_ship_surge() {
    npx surge ./dist 2>/dev/null || npx surge ./build 2>/dev/null || npx surge .
}

cua_ship_netlify() {
    npx netlify deploy --prod
}

cua_ship_vercel() {
    npx vercel --prod
}

# ============================================
# PREVIEW Functions
# ============================================

cua_preview() {
    local project="${1:-.}"
    local port="${2:-8080}"
    
    cd "$project" 2>/dev/null || { echo "Project not found"; return 1; }
    
    echo "👁️ Starting preview on port $port"
    
    # Auto-detect and start dev server
    if [[ -f "package.json" ]]; then
        if grep -q '"dev"' package.json; then
            npm run dev &
        elif grep -q '"start"' package.json; then
            npm start &
        else
            npx serve -l $port . &
        fi
    elif [[ -f "index.html" ]]; then
        python -m http.server $port &
    elif [[ -d "dist" ]]; then
        python -m http.server $port --directory dist &
    elif [[ -d "build" ]]; then
        python -m http.server $port --directory build &
    else
        python -m http.server $port &
    fi
    
    echo $! > "$CUA_LOGS/preview.pid"
    sleep 2
    echo "✅ Preview running at http://localhost:$port"
    echo "Stop with: tcc cua preview-stop"
}

cua_preview_stop() {
    if [[ -f "$CUA_LOGS/preview.pid" ]]; then
        kill $(cat "$CUA_LOGS/preview.pid") 2>/dev/null
        rm -f "$CUA_LOGS/preview.pid"
        echo "Preview stopped"
    else
        pkill -f "http.server" 2>/dev/null
        pkill -f "serve" 2>/dev/null
        echo "Stopped preview servers"
    fi
}

# ============================================
# BROWSER Automation (Playwright)
# ============================================

cua_browser() {
    local action="$1"
    shift
    
    case "$action" in
        open)
            cua_browser_open "$@"
            ;;
        screenshot)
            cua_browser_screenshot "$@"
            ;;
        pdf)
            cua_browser_pdf "$@"
            ;;
        run)
            cua_browser_run "$@"
            ;;
        *)
            echo "Browser automation (via Playwright MCP)"
            echo ""
            echo "Usage: tcc cua browser <action>"
            echo ""
            echo "Actions:"
            echo "  open <url>              Open URL in browser"
            echo "  screenshot <url> <out>  Take screenshot"
            echo "  pdf <url> <out>         Generate PDF"
            echo "  run <script.js>         Run Playwright script"
            ;;
    esac
}

cua_browser_open() {
    local url="$1"
    [[ -z "$url" ]] && { echo "Usage: tcc cua browser open <url>"; return 1; }
    
    # Use termux-open or xdg-open
    if command -v termux-open-url &>/dev/null; then
        termux-open-url "$url"
    elif command -v xdg-open &>/dev/null; then
        xdg-open "$url"
    else
        echo "Open in browser: $url"
    fi
}

cua_browser_screenshot() {
    local url="$1"
    local output="${2:-screenshot.png}"
    
    [[ -z "$url" ]] && { echo "Usage: tcc cua browser screenshot <url> [output.png]"; return 1; }
    
    # Generate Playwright script
    local script=$(mktemp --suffix=.js)
    cat > "$script" << EOF
const { chromium } = require('playwright');
(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.goto('$url');
    await page.screenshot({ path: '$output', fullPage: true });
    await browser.close();
    console.log('Screenshot saved: $output');
})();
EOF
    
    npx playwright install chromium 2>/dev/null
    node "$script"
    rm -f "$script"
}

cua_browser_pdf() {
    local url="$1"
    local output="${2:-output.pdf}"
    
    [[ -z "$url" ]] && { echo "Usage: tcc cua browser pdf <url> [output.pdf]"; return 1; }
    
    local script=$(mktemp --suffix=.js)
    cat > "$script" << EOF
const { chromium } = require('playwright');
(async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.goto('$url');
    await page.pdf({ path: '$output', format: 'A4' });
    await browser.close();
    console.log('PDF saved: $output');
})();
EOF
    
    npx playwright install chromium 2>/dev/null
    node "$script"
    rm -f "$script"
}

cua_browser_run() {
    local script="$1"
    [[ -z "$script" ]] && { echo "Usage: tcc cua browser run <script.js>"; return 1; }
    [[ ! -f "$script" ]] && { echo "Script not found: $script"; return 1; }
    
    node "$script"
}

# ============================================
# PROJECT Scaffolding
# ============================================

cua_create() {
    local template="$1"
    local name="$2"
    
    [[ -z "$template" || -z "$name" ]] && {
        echo "Usage: tcc cua create <template> <name>"
        echo ""
        echo "Templates:"
        echo "  react       React + Vite"
        echo "  vue         Vue 3 + Vite"
        echo "  node        Node.js API"
        echo "  python      Python project"
        echo "  html        Static HTML/CSS/JS"
        return 1
    }
    
    echo "📁 Creating $template project: $name"
    
    case "$template" in
        react)
            npm create vite@latest "$name" -- --template react
            ;;
        vue)
            npm create vite@latest "$name" -- --template vue
            ;;
        node)
            mkdir -p "$name" && cd "$name"
            npm init -y
            echo 'console.log("Hello from Node.js!");' > index.js
            ;;
        python)
            mkdir -p "$name" && cd "$name"
            echo "# $name" > README.md
            echo "" > requirements.txt
            echo 'print("Hello from Python!")' > main.py
            ;;
        html)
            mkdir -p "$name"/{css,js}
            echo '<!DOCTYPE html><html><head><title>'"$name"'</title><link rel="stylesheet" href="css/style.css"></head><body><h1>Hello!</h1><script src="js/main.js"></script></body></html>' > "$name/index.html"
            echo 'body { font-family: system-ui; }' > "$name/css/style.css"
            echo 'console.log("Ready!");' > "$name/js/main.js"
            ;;
    esac
    
    echo "✅ Created: $name"
}

# ============================================
# Main Handler
# ============================================

cua_main() {
    case "$1" in
        build) shift; cua_build "$@" ;;
        ship) shift; cua_ship "$@" ;;
        preview) shift; cua_preview "$@" ;;
        preview-stop) cua_preview_stop ;;
        browser) shift; cua_browser "$@" ;;
        create) shift; cua_create "$@" ;;
        *)
            echo "CUA - Computer Use Agent"
            echo ""
            echo "Usage: tcc cua <command>"
            echo ""
            echo "Commands:"
            echo "  build [path] [type]     Build project"
            echo "  ship <target> [path]    Deploy (github/npm/surge/netlify/vercel)"
            echo "  preview [path] [port]   Start dev server"
            echo "  preview-stop            Stop preview"
            echo "  browser <action>        Browser automation"
            echo "  create <template> <name>  Create new project"
            ;;
    esac
}
