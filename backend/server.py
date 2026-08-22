import json
import os
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

PRODUCTS = [
    {"name": "Sneakers", "price": 120, "category": "Men", "image": "sneakers"},
    {"name": "Smartphone", "price": 999, "category": "Electronics", "image": "smartphone"},
    {"name": "Handbag", "price": 250, "category": "Women", "image": "handbag"},
    {"name": "Headphones", "price": 180, "category": "Electronics", "image": "headphones"},
]


class AppHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/products":
            payload = json.dumps(PRODUCTS).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        super().do_GET()

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    os.chdir(os.environ.get("WEB_ROOT", "/app/build/web"))
    port = int(os.environ.get("PORT", "80"))
    server = ThreadingHTTPServer(("0.0.0.0", port), AppHandler)
    print(f"Serving Flutter web and catalog API on port {port}", flush=True)
    server.serve_forever()
