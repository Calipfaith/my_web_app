import json
import logging
import os
from decimal import Decimal
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

import boto3

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PRODUCTS = [
    {"name": "Sneakers", "price": 120, "category": "Men", "image": "sneakers"},
    {"name": "Smartphone", "price": 999, "category": "Electronics", "image": "smartphone"},
    {"name": "Handbag", "price": 250, "category": "Women", "image": "handbag"},
    {"name": "Headphones", "price": 180, "category": "Electronics", "image": "headphones"},
]


class AppHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/products":
            try:
                payload = json.dumps(
                    get_products(),
                    default=lambda value: float(value)
                    if isinstance(value, Decimal)
                    else str(value),
                ).encode("utf-8")
                status = 200
            except Exception as error:
                logger.exception("Catalog request failed")
                payload = b'{"error":"Catalog temporarily unavailable"}'
                status = 503
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        super().do_GET()

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def get_products():
    table_name = os.environ.get("PRODUCTS_TABLE")
    if not table_name:
        return PRODUCTS

    region = os.environ.get("AWS_REGION") or os.environ.get(
        "AWS_DEFAULT_REGION", "ap-southeast-1"
    )
    table = boto3.resource("dynamodb", region_name=region).Table(table_name)
    items = []
    scan_kwargs = {
        "ProjectionExpression": "productId, #n, price, category, image",
        "ExpressionAttributeNames": {"#n": "name"},
    }
    while True:
        response = table.scan(**scan_kwargs)
        items.extend(response.get("Items", []))
        last_key = response.get("LastEvaluatedKey")
        if not last_key:
            return items
        scan_kwargs["ExclusiveStartKey"] = last_key


if __name__ == "__main__":
    os.chdir(os.environ.get("WEB_ROOT", "/app/build/web"))
    port = int(os.environ.get("PORT", "80"))
    server = ThreadingHTTPServer(("0.0.0.0", port), AppHandler)
    print(f"Serving Flutter web and catalog API on port {port}", flush=True)
    server.serve_forever()
