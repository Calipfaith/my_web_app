import json
import logging
import os
import uuid
from decimal import Decimal
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlencode
from urllib.parse import unquote
from urllib.request import Request, urlopen

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
    def do_POST(self):
        if self.path not in ("/api/orders", "/api/payment-intents"):
            self.send_error(404)
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            order = json.loads(self.rfile.read(length))
            if self.path == "/api/orders":
                order_id = create_order(order)
                self._send_json(201, {"orderId": order_id, "status": "pending"})
            else:
                payment = create_payment_intent(order)
                self._send_json(201, payment)
        except (ValueError, json.JSONDecodeError):
            self._send_json(400, {"error": "Invalid order payload"})
        except Exception:
            logger.exception("Order request failed")
            self._send_json(503, {"error": "Order service temporarily unavailable"})

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
            self._send_json(status, json.loads(payload))
            return
        if self.path.startswith("/api/orders/"):
            order_id = unquote(self.path.removeprefix("/api/orders/"))
            try:
                order = get_order(order_id)
                if order is None:
                    self._send_json(404, {"error": "Order not found"})
                else:
                    self._send_json(200, order)
            except Exception:
                logger.exception("Order lookup failed")
                self._send_json(503, {"error": "Order service temporarily unavailable"})
            return
        super().do_GET()

    def _send_json(self, status, data):
        payload = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

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


def create_order(order):
    required = ("address", "contact", "paymentMethod", "cartItems")
    if any(not order.get(field) for field in required):
        raise ValueError("Missing order field")

    order_id = str(uuid.uuid4())
    table_name = os.environ.get("ORDERS_TABLE")
    if not table_name:
        return order_id

    region = os.environ.get("AWS_REGION") or os.environ.get(
        "AWS_DEFAULT_REGION", "ap-southeast-1"
    )
    table = boto3.resource("dynamodb", region_name=region).Table(table_name)
    table.put_item(
        Item={
            "orderId": order_id,
            "address": str(order["address"]),
            "contact": str(order["contact"]),
            "paymentMethod": str(order["paymentMethod"]),
            "cartItems": order["cartItems"],
            "status": "pending",
        }
    )
    return order_id


def get_order(order_id):
    table_name = os.environ.get("ORDERS_TABLE")
    if not table_name:
        return {"orderId": order_id, "status": "pending"}

    region = os.environ.get("AWS_REGION") or os.environ.get(
        "AWS_DEFAULT_REGION", "ap-southeast-1"
    )
    table = boto3.resource("dynamodb", region_name=region).Table(table_name)
    response = table.get_item(Key={"orderId": order_id})
    order = response.get("Item")
    if order is None:
        return None
    return {"orderId": order["orderId"], "status": order.get("status", "pending")}


def create_payment_intent(payment):
    secret_key = os.environ.get("STRIPE_SECRET_KEY")
    if not secret_key:
        raise RuntimeError("Stripe is not configured")
    if not payment.get("orderId") or not payment.get("amount"):
        raise ValueError("Missing payment field")

    amount = int(payment["amount"])
    if amount <= 0:
        raise ValueError("Payment amount must be positive")

    request = Request(
        "https://api.stripe.com/v1/payment_intents",
        data=urlencode({
            "amount": amount,
            "currency": payment.get("currency", "myr"),
            "metadata[orderId]": payment["orderId"],
            "payment_method_types[]": "card",
        }).encode("utf-8"),
        headers={"Authorization": f"Bearer {secret_key}"},
        method="POST",
    )
    with urlopen(request, timeout=15) as response:
        stripe_payment = json.load(response)
    return {
        "paymentIntentId": stripe_payment["id"],
        "clientSecret": stripe_payment["client_secret"],
        "status": stripe_payment["status"],
    }


if __name__ == "__main__":
    os.chdir(os.environ.get("WEB_ROOT", "/app/build/web"))
    port = int(os.environ.get("PORT", "80"))
    server = ThreadingHTTPServer(("0.0.0.0", port), AppHandler)
    print(f"Serving Flutter web and catalog API on port {port}", flush=True)
    server.serve_forever()
