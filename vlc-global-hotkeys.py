#!/usr/bin/env python3
"""
VLC Global Hotkeys Controller
Provides system-wide keyboard shortcuts for VLC control
"""

import keyboard
import requests
import time
import sys

# VLC Configuration
VLC_URL = "http://localhost:8080/requests/status.xml"
VLC_PASSWORD = "test123"

def send_vlc_command(command, value=None):
    """Send command to VLC HTTP interface"""
    try:
        params = {"command": command}
        if value is not None:
            params["val"] = value
        
        response = requests.get(VLC_URL, 
                              params=params,
                              auth=('', VLC_PASSWORD), 
                              timeout=2)
        
        if response.status_code == 200:
            print(f"✅ VLC command sent: {command}" + (f" (val={value})" if value else ""))
        else:
            print(f"❌ VLC error: {response.status_code}")
            
    except requests.RequestException as e:
        print(f"❌ Connection error: {e}")

def test_vlc_connection():
    """Test if VLC is responding"""
    print("Testing VLC connection...")
    try:
        response = requests.get(VLC_URL, 
                              auth=('', VLC_PASSWORD), 
                              timeout=5)
        if response.status_code == 200:
            print("✅ VLC connection successful!")
            return True
        else:
            print(f"❌ VLC returned status {response.status_code}")
            return False
    except requests.RequestException as e:
        print(f"❌ Cannot connect to VLC: {e}")
        print("Make sure VLC is running with: vlc --intf dummy --extraintf http --http-password 'test123' &")
        return False

def setup_hotkeys():
    """Setup global keyboard shortcuts"""
    print("\nSetting up global hotkeys...")
    
    # Basic playback controls
    keyboard.add_hotkey('ctrl+alt+space', lambda: send_vlc_command('pl_pause'))
    keyboard.add_hotkey('ctrl+alt+s', lambda: send_vlc_command('pl_stop'))
    
    # Seeking
    keyboard.add_hotkey('ctrl+alt+left', lambda: send_vlc_command('seek', '-10'))
    keyboard.add_hotkey('ctrl+alt+right', lambda: send_vlc_command('seek', '+10'))
    keyboard.add_hotkey('ctrl+alt+shift+left', lambda: send_vlc_command('seek', '-60'))
    keyboard.add_hotkey('ctrl+alt+shift+right', lambda: send_vlc_command('seek', '+60'))
    
    # Volume control
    keyboard.add_hotkey('ctrl+alt+up', lambda: send_vlc_command('volume', '+20'))
    keyboard.add_hotkey('ctrl+alt+down', lambda: send_vlc_command('volume', '-20'))
    
    # Playlist navigation
    keyboard.add_hotkey('ctrl+alt+n', lambda: send_vlc_command('pl_next'))
    keyboard.add_hotkey('ctrl+alt+p', lambda: send_vlc_command('pl_previous'))
    
    # Exit hotkey
    keyboard.add_hotkey('ctrl+alt+q', lambda: sys.exit(0))
    
    print("✅ Global hotkeys registered!")
    print("\n📋 Available shortcuts:")
    print("  Ctrl+Alt+Space    - Play/Pause")
    print("  Ctrl+Alt+S        - Stop")
    print("  Ctrl+Alt+←/→      - Seek ±10 seconds")
    print("  Ctrl+Alt+Shift+←/→ - Seek ±60 seconds")
    print("  Ctrl+Alt+↑/↓      - Volume ±20")
    print("  Ctrl+Alt+N        - Next track")
    print("  Ctrl+Alt+P        - Previous track")
    print("  Ctrl+Alt+Q        - Quit this script")

def main():
    """Main function"""
    print("🎵 VLC Global Hotkeys Controller")
    print("=" * 40)
    
    # Test VLC connection first
    if not test_vlc_connection():
        sys.exit(1)
    
    # Setup hotkeys
    setup_hotkeys()
    
    print(f"\n🎯 Listening for global hotkeys... (Press Ctrl+Alt+Q to quit)")
    print("💡 Make sure VLC is running and try pressing Ctrl+Alt+Space")
    
    try:
        # Keep the script running
        keyboard.wait()
    except KeyboardInterrupt:
        print("\n👋 Exiting VLC Global Hotkeys Controller")
        sys.exit(0)

if __name__ == "__main__":
    main()
