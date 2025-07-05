#!/bin/bash

# VLC Master Launcher Script
# Starts all VLC web controller components with proper permissions

set -e  # Exit on any error

VLC_DIR="$(pwd)"
VENV_DIR="$VLC_DIR/vlc-env"
VLC_PASSWORD="test123"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎵 VLC Web Controller Master Launcher${NC}"
echo "=========================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if port is in use
port_in_use() {
    netstat -tuln 2>/dev/null | grep -q ":$1 "
}

# Function to kill processes on specific ports
kill_port() {
    local port=$1
    echo -e "${YELLOW}🔍 Checking port $port...${NC}"
    if port_in_use $port; then
        echo -e "${YELLOW}⚠️  Port $port is in use, killing processes...${NC}"
        sudo lsof -ti:$port | xargs sudo kill -9 2>/dev/null || true
        sleep 1
    fi
}

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    pkill -f "vlc.*http" 2>/dev/null || true
    pkill -f "cors-proxy.py" 2>/dev/null || true
    pkill -f "http.server" 2>/dev/null || true
    pkill -f "vlc-global-hotkeys.py" 2>/dev/null || true
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    exit 0
}

# Set trap for cleanup on Ctrl+C
trap cleanup SIGINT SIGTERM

# Step 1: Check dependencies
echo -e "${BLUE}📋 Checking dependencies...${NC}"

if ! command_exists vlc; then
    echo -e "${RED}❌ VLC not found. Install with: sudo apt install vlc${NC}"
    exit 1
fi

if ! command_exists python3; then
    echo -e "${RED}❌ Python3 not found. Install with: sudo apt install python3${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencies OK${NC}"

# Step 2: Clean up any existing processes
echo -e "\n${BLUE}🧹 Cleaning up existing processes...${NC}"
kill_port 8080  # VLC
kill_port 5000  # CORS proxy  
kill_port 3000  # Web server
pkill -f "vlc.*http" 2>/dev/null || true

# Step 3: Check/create virtual environment
echo -e "\n${BLUE}🐍 Setting up Python virtual environment...${NC}"

if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}📦 Creating virtual environment...${NC}"
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install/update packages
echo -e "${YELLOW}📦 Installing/updating Python packages...${NC}"
pip install --quiet requests keyboard

# Step 4: Start VLC with HTTP interface
echo -e "\n${BLUE}🎬 Starting VLC with HTTP interface...${NC}"
vlc --intf dummy --extraintf http --http-password "$VLC_PASSWORD" &
VLC_PID=$!

# Wait for VLC to start
sleep 3

# Check if VLC started successfully
if ! port_in_use 8080; then
    echo -e "${RED}❌ VLC failed to start on port 8080${NC}"
    exit 1
fi
echo -e "${GREEN}✅ VLC started (PID: $VLC_PID)${NC}"

# Step 5: Start CORS proxy
echo -e "\n${BLUE}🌐 Starting CORS proxy...${NC}"
if [ ! -f "cors-proxy.py" ]; then
    echo -e "${RED}❌ cors-proxy.py not found in current directory${NC}"
    cleanup
    exit 1
fi

python3 cors-proxy.py &
PROXY_PID=$!
sleep 2

if ! port_in_use 5000; then
    echo -e "${RED}❌ CORS proxy failed to start on port 5000${NC}"
    cleanup
    exit 1
fi
echo -e "${GREEN}✅ CORS proxy started (PID: $PROXY_PID)${NC}"

# Step 6: Start web server
echo -e "\n${BLUE}🌍 Starting web server...${NC}"
python3 -m http.server 3000 &
WEB_PID=$!
sleep 2

if ! port_in_use 3000; then
    echo -e "${RED}❌ Web server failed to start on port 3000${NC}"
    cleanup
    exit 1
fi
echo -e "${GREEN}✅ Web server started (PID: $WEB_PID)${NC}"

# Step 7: Start global hotkeys (with sudo)
echo -e "\n${BLUE}⌨️  Starting global hotkeys...${NC}"
if [ ! -f "vlc-global-hotkeys.py" ]; then
    echo -e "${YELLOW}⚠️  vlc-global-hotkeys.py not found, skipping global hotkeys${NC}"
    HOTKEYS_PID=""
else
    echo -e "${YELLOW}🔐 Starting global hotkeys (requires sudo)...${NC}"
    sudo "$VENV_DIR/bin/python" vlc-global-hotkeys.py &
    HOTKEYS_PID=$!
    sleep 2
    echo -e "${GREEN}✅ Global hotkeys started (PID: $HOTKEYS_PID)${NC}"
fi

# Step 8: Show status and URLs
echo -e "\n${GREEN}🎉 VLC Web Controller is now running!${NC}"
echo "=========================================="
echo -e "${BLUE}📊 Service Status:${NC}"
echo -e "  VLC HTTP Interface:  ${GREEN}http://localhost:8080${NC} (password: $VLC_PASSWORD)"
echo -e "  CORS Proxy:          ${GREEN}http://localhost:5000${NC}"
echo -e "  Web Interface:       ${GREEN}http://localhost:3000/vlc-web-interface.html${NC}"
if [ -n "$HOTKEYS_PID" ]; then
    echo -e "  Global Hotkeys:      ${GREEN}Active${NC}"
fi

echo -e "\n${BLUE}⌨️  Global Hotkeys:${NC}"
if [ -n "$HOTKEYS_PID" ]; then
    echo "  Ctrl+Alt+Space    - Play/Pause"
    echo "  Ctrl+Alt+S        - Stop"
    echo "  Ctrl+Alt+←/→      - Seek ±10 seconds"
    echo "  Ctrl+Alt+↑/↓      - Volume ±20"
    echo "  Ctrl+Alt+Q        - Quit hotkeys"
else
    echo "  (Not available - vlc-global-hotkeys.py not found)"
fi

echo -e "\n${BLUE}🎯 Usage:${NC}"
echo "  1. Open: http://localhost:3000/vlc-web-interface.html"
echo "  2. Enter password: $VLC_PASSWORD"
echo "  3. Enter file path: media/my_file.mp3"
echo "  4. Click 'PLAY FILE'"

echo -e "\n${YELLOW}Press Ctrl+C to stop all services${NC}"

# Keep script running and show logs
echo -e "\n${BLUE}📜 Live logs (Ctrl+C to exit):${NC}"
echo "=========================================="

# Wait for user to stop
wait
