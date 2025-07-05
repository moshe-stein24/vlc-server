#!/usr/bin/env python3
import http.server
import socketserver
import urllib.request
import urllib.parse
from urllib.error import URLError
import base64

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/vlc/'):
            vlc_path = self.path[5:]
            vlc_url = f"http://localhost:8080/{vlc_path}"
            
            try:
                vlc_password = self.headers.get('VLC-Password', '')
                print(f"Received password: '{vlc_password}'")
                
                request = urllib.request.Request(vlc_url)
                if vlc_password:
                    credentials = base64.b64encode(f":{vlc_password}".encode()).decode()
                    request.add_header('Authorization', f'Basic {credentials}')
                    print(f"Added auth header")
                
                with urllib.request.urlopen(request) as response:
                    content = response.read().decode()
                
                self.send_response(200)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
                self.send_header('Access-Control-Allow-Headers', 'Content-Type, VLC-Password, Authorization')
                self.send_header('Content-Type', 'text/xml')
                self.end_headers()
                self.wfile.write(content.encode())
                
            except URLError as e:
                print(f"Error: {e}")
                self.send_response(500)
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(f"Error: {e}".encode())
        else:
            super().do_GET()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, VLC-Password, Authorization')
        self.end_headers()

if __name__ == "__main__":
    with socketserver.TCPServer(("", 5000), CORSHTTPRequestHandler) as httpd:
        print("CORS proxy running on port 5000")
        httpd.serve_forever()
