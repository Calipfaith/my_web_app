import json
import hashlib
import hmac
import logging
import os
import time
import uuid
from decimal import Decimal
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlencode
from urllib.parse import unquote
from urllib.request import Request, urlopen

import boto3
from botocore.exceptions import ClientError
import jwt

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PRODUCTS = [
    {"name": "Sneakers", "price": 120, "category": "Men", "image": "sneakers"},
    {"name": "Smartphone", "price": 999, "category": "Electronics", "image": "smartphone"},
    {"name": "Handbag", "price": 250, "category": "Women", "image": "handbag"},
    {"name": "Headphones", "price": 180, "category": "Electronics", "image": "headphones"},
]


class AppHandler(SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(204)
        self.end_headers()

    def do_POST(self):
        if self.path not in (
            "/api/orders",
            "/api/payment-intents",
            "/api/payment-intents/verify",
            "/api/checkout-sessions",
            "/api/checkout-sessions/verify",
            "/api/webhooks/stripe",
            "/api/auth/token",
            "/api/auth/refresh",
            "/api/auth/revoke",
            "/api/profile",
            "/api/rewards/redeem",
            "/api/queen/events",
            "/api/bee/drops",
            "/api/bee/collaborations",
            "/api/live-sessions",
        ) and not self.path.startswith("/api/chat/") and not self.path.startswith("/api/bee/drops/") and not self.path.startswith("/api/bee/collaborations/") and not self.path.startswith("/api/live-sessions/"):
            self.send_error(404)
            return

        try:
            user = None
            if self.path not in (
                "/api/webhooks/stripe",
                "/api/auth/token",
                "/api/auth/refresh",
                "/api/auth/revoke",
            ):
                user = require_user(self.headers.get("Authorization"))
            length = int(self.headers.get("Content-Length", "0"))
            raw_body = self.rfile.read(length)
            if self.path == "/api/webhooks/stripe":
                if not verify_stripe_signature(
                    raw_body, self.headers.get("Stripe-Signature", "")
                ):
                    self._send_json(400, {"error": "Invalid webhook signature"})
                    return
                event = json.loads(raw_body)
                processed = process_stripe_event(event)
                self._send_json(200, {"received": True, "processed": processed})
                return

            order = json.loads(raw_body)
            if self.path == "/api/orders":
                order_id = create_order(order, user)
                self._send_json(201, {"orderId": order_id, "status": "pending"})
            elif self.path == "/api/payment-intents":
                payment = create_payment_intent(order)
                self._send_json(201, payment)
            elif self.path == "/api/checkout-sessions":
                session = create_checkout_session(order)
                self._send_json(201, session)
            elif self.path == "/api/auth/token":
                tokens = exchange_cognito_code(order)
                self._send_json(200, tokens)
            elif self.path == "/api/auth/refresh":
                tokens = refresh_cognito_session(order)
                self._send_json(200, tokens)
            elif self.path == "/api/auth/revoke":
                revoke_cognito_session(order)
                self._send_json(200, {"revoked": True})
            elif self.path == "/api/profile":
                profile = update_profile(order, user)
                self._send_json(200, profile)
            elif self.path == "/api/rewards/redeem":
                self._send_json(200, redeem_reward(order, user))
            elif self.path.startswith("/api/chat/"):
                drop_id = unquote(self.path.removeprefix("/api/chat/"))
                if not order.get("message"):
                    raise ValueError("Missing chat message")
                comment = {"user": user["sub"], "message": str(order["message"]), "dropId": drop_id, "createdAt": int(time.time())}
                chat_table = _named_table("QUEEN_CHAT_TABLE")
                if chat_table is not None:
                    chat_table.put_item(Item={"commentId": str(uuid.uuid4()), **comment})
                self._send_json(201, {"dropId": drop_id, "comment": comment})
            elif self.path == "/api/queen/events":
                if "queen" not in [group.lower() for group in user.get("groups", [])]:
                    raise PermissionError("Queen access required")
                if not order.get("title") or not order.get("date"):
                    raise ValueError("Event title and date are required")
                event = {"eventId": str(uuid.uuid4()), "title": str(order["title"]), "date": str(order["date"]), "reward": str(order.get("reward", "0 Nectar"))}
                table = _named_table("QUEEN_EVENTS_TABLE")
                if table is not None:
                    table.put_item(Item=event)
                self._send_json(201, event)
            elif self.path == "/api/bee/drops":
                if "bee" not in [group.lower() for group in user.get("groups", [])]:
                    raise PermissionError("Bee access required")
                if not order.get("title") or not order.get("date") or not order.get("product"):
                    raise ValueError("Drop title, date, and product are required")
                drop = {"dropId": str(uuid.uuid4()), "title": str(order["title"]), "date": str(order["date"]), "product": str(order["product"]), "hostId": user["sub"], "hostType": "bee"}
                table = _named_table("QUEEN_DROPS_TABLE")
                if table is not None:
                    table.put_item(Item=drop)
                self._send_json(201, drop)
            elif self.path == "/api/bee/collaborations":
                if "bee" not in [group.lower() for group in user.get("groups", [])]:
                    raise PermissionError("Bee access required")
                if not order.get("username"):
                    raise ValueError("Co-host username is required")
                invitation = {"collaborationId": str(uuid.uuid4()), "inviterId": user["sub"], "invitee": str(order["username"]), "status": "pending", "createdAt": int(time.time())}
                table = _named_table("BEE_COLLABORATIONS_TABLE")
                if table is not None:
                    table.put_item(Item=invitation)
                self._send_json(201, invitation)
            elif self.path == "/api/live-sessions":
                if not _can_host_live(user):
                    raise PermissionError("Live host access required")
                if not order.get("title"):
                    raise ValueError("Live session title is required")
                session = create_ivs_session(order, user)
                self._send_json(201, session)
            elif self.path.startswith("/api/bee/collaborations/") and self.path.endswith("/decision"):
                collaboration_id = unquote(self.path.removeprefix("/api/bee/collaborations/").removesuffix("/decision"))
                decision = str(order.get("decision", ""))
                if decision not in ("accepted", "rejected"):
                    raise ValueError("Invalid collaboration decision")
                table = _named_table("BEE_COLLABORATIONS_TABLE")
                if table is None:
                    self._send_json(200, {"collaborationId": collaboration_id, "status": decision})
                else:
                    response = table.update_item(Key={"collaborationId": collaboration_id}, UpdateExpression="SET #status = :status", ExpressionAttributeNames={"#status": "status"}, ExpressionAttributeValues={":status": decision}, ReturnValues="ALL_NEW")
                    self._send_json(200, response.get("Attributes", {"collaborationId": collaboration_id, "status": decision}))
            elif self.path.startswith("/api/bee/drops/") and self.path.endswith("/status"):
                if "bee" not in [group.lower() for group in user.get("groups", [])]:
                    raise PermissionError("Bee access required")
                drop_id = unquote(self.path.removeprefix("/api/bee/drops/").removesuffix("/status"))
                status = str(order.get("status", "scheduled"))
                if status not in ("scheduled", "live", "completed"):
                    raise ValueError("Invalid drop status")
                table = _named_table("QUEEN_DROPS_TABLE")
                if table is None:
                    self._send_json(200, {"dropId": drop_id, "status": status})
                else:
                    response = table.update_item(Key={"dropId": drop_id}, UpdateExpression="SET #status = :status", ExpressionAttributeNames={"#status": "status"}, ExpressionAttributeValues={":status": status}, ReturnValues="ALL_NEW")
                    self._send_json(200, response.get("Attributes", {"dropId": drop_id, "status": status}))
            elif self.path.startswith("/api/live-sessions/") and self.path.endswith("/status"):
                user = require_user(self.headers.get("Authorization"))
                if not _can_host_live(user):
                    raise PermissionError("Live host access required")
                session_id = unquote(self.path.removeprefix("/api/live-sessions/").removesuffix("/status"))
                status = str(order.get("status", "scheduled"))
                if status not in ("scheduled", "live", "completed"):
                    raise ValueError("Invalid live session status")
                table = _named_table("QUEEN_DROPS_TABLE")
                if table is None:
                    self._send_json(200, {"dropId": session_id, "status": status})
                else:
                    response = table.update_item(Key={"dropId": session_id}, UpdateExpression="SET #status = :status", ExpressionAttributeNames={"#status": "status"}, ExpressionAttributeValues={":status": status}, ReturnValues="ALL_NEW")
                    self._send_json(200, response.get("Attributes", {"dropId": session_id, "status": status}))
            elif self.path.startswith("/api/live-sessions/") and self.path.endswith("/presence"):
                user = require_user(self.headers.get("Authorization"))
                session_id = unquote(self.path.removeprefix("/api/live-sessions/").removesuffix("/presence"))
                joining = bool(order.get("joining"))
                table = _named_table("QUEEN_DROPS_TABLE")
                if table is None:
                    self._send_json(200, {"dropId": session_id, "viewerCount": 0})
                else:
                    response = table.update_item(Key={"dropId": session_id}, UpdateExpression="ADD viewerCount :delta", ExpressionAttributeValues={":delta": 1 if joining else -1}, ReturnValues="ALL_NEW")
                    self._send_json(200, response.get("Attributes", {"dropId": session_id}))
            elif self.path.startswith("/api/live-sessions/") and self.path.endswith("/settle"):
                if not _can_host_live(user):
                    raise PermissionError("Live host access required")
                session_id = unquote(self.path.removeprefix("/api/live-sessions/").removesuffix("/settle"))
                amount = float(order.get("amount", 0))
                queen_rate = float(order.get("queenRate", 0.10))
                bee_rate = float(order.get("beeRate", 0.10))
                if amount <= 0 or queen_rate < 0 or bee_rate < 0 or queen_rate + bee_rate > 1:
                    raise ValueError("Invalid settlement values")
                settlement = {"settlementId": str(uuid.uuid4()), "sessionId": session_id, "amount": amount, "queenCommission": round(amount * queen_rate, 2), "beeCommission": round(amount * bee_rate, 2), "platformAmount": round(amount * (1 - queen_rate - bee_rate), 2), "createdAt": int(time.time())}
                table = _named_table("LIVE_SETTLEMENTS_TABLE")
                if table is not None:
                    table.put_item(Item=settlement)
                self._send_json(201, settlement)
            else:
                payment = verify_checkout_session(order)
                self._send_json(200, payment)
        except PermissionError as error:
            self._send_json(401, {"error": str(error)})
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
        if self.path == "/api/orders":
            try:
                user = require_user(self.headers.get("Authorization"))
                self._send_json(200, list_customer_orders(user))
            except PermissionError as error:
                self._send_json(401, {"error": str(error)})
            except Exception:
                logger.exception("Order history lookup failed")
                self._send_json(503, {"error": "Order service temporarily unavailable"})
            return
        if self.path == "/api/profile":
            try:
                user = require_user(self.headers.get("Authorization"))
                self._send_json(200, get_profile(user))
            except PermissionError as error:
                self._send_json(401, {"error": str(error)})
            except Exception:
                logger.exception("Profile lookup failed")
                self._send_json(503, {"error": "Profile service temporarily unavailable"})
            return
        if self.path == "/api/rewards":
            try:
                user = require_user(self.headers.get("Authorization"))
                self._send_json(200, get_profile(user).get("rewards", {"points": 0, "coupons": [], "transactions": []}))
            except PermissionError as error:
                self._send_json(401, {"error": str(error)})
            return
        if self.path == "/api/bee/dashboard":
            try:
                user = require_user(self.headers.get("Authorization"))
                if "bee" not in [group.lower() for group in user.get("groups", [])]:
                    raise PermissionError("Bee access required")
                self._send_json(200, {
                    "nextDrop": "No drop scheduled",
                    "honeycombs": 0,
                    "views": 0,
                    "joinedHives": 0,
                    "coHostRequests": 0,
                    "sales": 0,
                    "nectar": 0,
                    "honeyPotEntries": 0,
                    "viewers": 0,
                    "totalSales": 0,
                    "tips": 0,
                })
            except PermissionError as error:
                self._send_json(403, {"error": str(error)})
            return
        if self.path in ("/api/kpis/partner", "/api/kpis/admin", "/api/kpis/investor"):
            try:
                require_user(self.headers.get("Authorization"))
                snapshot = build_kpi_snapshot()
                persist_kpi_snapshot(snapshot)
                trends = build_kpi_trends(snapshot)
                if self.path == "/api/kpis/partner":
                    self._send_json(200, {
                        "activeClients": snapshot["activeCustomers"],
                        "fulfilledOrders": snapshot["paidOrders"],
                        "commissionPool": snapshot["commissionPool"],
                        "avgOrderValue": snapshot["avgOrderValue"],
                        "liveSessions": snapshot["liveSessions"],
                        "activeClientsTrend": trends["activeCustomers"],
                        "fulfilledOrdersTrend": trends["paidOrders"],
                        "commissionPoolTrend": trends["commissionPool"],
                    })
                elif self.path == "/api/kpis/admin":
                    self._send_json(200, {
                        "catalogProducts": snapshot["catalogProducts"],
                        "pendingOrders": snapshot["pendingOrders"],
                        "paidOrders": snapshot["paidOrders"],
                        "gmv": snapshot["gmv"],
                        "liveSessions": snapshot["liveSessions"],
                        "pendingOrdersTrend": trends["pendingOrders"],
                        "gmvTrend": trends["gmv"],
                    })
                else:
                    self._send_json(200, {
                        "gmv": snapshot["gmv"],
                        "activeCustomers": snapshot["activeCustomers"],
                        "paidOrders": snapshot["paidOrders"],
                        "commissionPool": snapshot["commissionPool"],
                        "settlementRate": snapshot["settlementRate"],
                        "nectarIssued": snapshot["nectarIssued"],
                        "settlementRateTrend": trends["settlementRate"],
                        "gmvTrend": trends["gmv"],
                    })
            except PermissionError as error:
                self._send_json(401, {"error": str(error)})
            except Exception:
                logger.exception("KPI lookup failed")
                self._send_json(503, {"error": "KPI service temporarily unavailable"})
            return
        if self.path.startswith("/api/live-sessions/"):
            try:
                user = require_user(self.headers.get("Authorization"))
                if not _can_host_live(user):
                    raise PermissionError("Live session access required")
                session_id = unquote(self.path.removeprefix("/api/live-sessions/"))
                table = _named_table("QUEEN_DROPS_TABLE")
                session = table.get_item(Key={"dropId": session_id}).get("Item") if table is not None else None
                if session is None:
                    session = {"dropId": session_id, "title": "Live Drop", "status": "scheduled", "product": "Featured product", "viewerCount": 0, "nectar": 0}
                self._send_json(200, session)
            except PermissionError as error:
                self._send_json(403, {"error": str(error)})
            return
        if self.path == "/api/bee/collaborations":
            try:
                user = require_user(self.headers.get("Authorization"))
                collaborations = _scan_table("BEE_COLLABORATIONS_TABLE")
                owned = [item for item in collaborations if item.get("inviterId") == user["sub"] or item.get("invitee") == user["sub"]]
                self._send_json(200, {"collaborations": owned})
            except PermissionError as error:
                self._send_json(401, {"error": str(error)})
            return
        if self.path in ("/api/queen/drops", "/api/queen/events", "/api/queen/rewards", "/api/queen/analytics") or self.path.startswith("/api/chat/"):
            try:
                user = require_user(self.headers.get("Authorization")) if self.path in ("/api/queen/analytics",) or self.path.startswith("/api/chat/") else None
                if self.path == "/api/queen/analytics" and "queen" not in [group.lower() for group in user.get("groups", [])]:
                    raise PermissionError("Queen access required")
                if self.path == "/api/queen/drops":
                    self._send_json(200, {"drops": _scan_table("QUEEN_DROPS_TABLE")})
                elif self.path == "/api/queen/events":
                    self._send_json(200, {"events": _scan_table("QUEEN_EVENTS_TABLE")})
                elif self.path == "/api/queen/rewards":
                    self._send_json(200, {"points": 0, "issued": 0, "redeemed": 0})
                elif self.path == "/api/queen/analytics":
                    self._send_json(200, {
                        "gmv": 0,
                        "repeatBuyers": 0,
                        "aov": 0,
                        "chatActivity": 0,
                        "dropParticipation": 0,
                        "activeBuyers": 0,
                        "engagement": 0,
                        "nectarIssued": 0,
                        "nectarRedeemed": 0,
                        "redemptionRate": 0,
                        "nextEvent": "No event scheduled",
                    })
                else:
                    drop_id = unquote(self.path.removeprefix("/api/chat/"))
                    comments = [item for item in _scan_table("QUEEN_CHAT_TABLE") if item.get("dropId") == drop_id]
                    self._send_json(200, {"comments": comments})
            except PermissionError as error:
                self._send_json(403, {"error": str(error)})
            return
        if self.path.startswith("/api/orders/"):
            try:
                user = require_user(self.headers.get("Authorization"))
                if self.path.endswith("/settlement"):
                    order_id = unquote(
                        self.path.removeprefix("/api/orders/").removesuffix("/settlement")
                    )
                    details = get_order_settlement_details(order_id, user)
                    if details is None:
                        self._send_json(404, {"error": "Order not found"})
                    else:
                        self._send_json(200, details)
                else:
                    order_id = unquote(self.path.removeprefix("/api/orders/"))
                    order = get_order(order_id, user)
                    if order is None:
                        self._send_json(404, {"error": "Order not found"})
                    else:
                        self._send_json(200, order)
            except PermissionError as error:
                self._send_json(401, {"error": str(error)})
            except Exception:
                logger.exception("Order lookup failed")
                self._send_json(503, {"error": "Order service temporarily unavailable"})
            return
        super().do_GET()

    def _send_json(self, status, data):
        payload = json.dumps(
            data,
            default=lambda value: float(value)
            if isinstance(value, Decimal)
            else str(value),
        ).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def end_headers(self):
        origin = self.headers.get("Origin")
        if origin and origin.startswith("http://localhost:"):
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
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

_jwks_client = None


def require_user(authorization):
    if os.environ.get("REQUIRE_AUTH", "false").lower() != "true":
        return {"sub": "local-preview", "groups": ["queen", "bee"]}
    if not authorization or not authorization.startswith("Bearer "):
        raise PermissionError("Authentication required")

    region = os.environ.get("AWS_REGION") or os.environ.get(
        "AWS_DEFAULT_REGION", "ap-southeast-1"
    )
    pool_id = os.environ.get("COGNITO_USER_POOL_ID")
    client_id = os.environ.get("COGNITO_APP_CLIENT_ID")
    if not pool_id or not client_id:
        raise RuntimeError("Cognito is not configured")
    issuer = os.environ.get(
        "COGNITO_ISSUER",
        f"https://cognito-idp.{region}.amazonaws.com/{pool_id}",
    )
    global _jwks_client
    if _jwks_client is None:
        _jwks_client = jwt.PyJWKClient(f"{issuer}/.well-known/jwks.json")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        signing_key = _jwks_client.get_signing_key_from_jwt(token).key
        claims = jwt.decode(
            token,
            signing_key,
            algorithms=["RS256"],
            issuer=issuer,
            options={"verify_aud": False},
        )
        if claims.get("token_use") != "access" or claims.get("client_id") != client_id:
            raise PermissionError("Invalid Cognito access token")
    except Exception as error:
        raise PermissionError("Invalid authentication token") from error
    return {"sub": claims["sub"], "groups": claims.get("cognito:groups", [])}


def exchange_cognito_code(payload):
    domain = os.environ.get("COGNITO_HOSTED_DOMAIN")
    client_id = os.environ.get("COGNITO_APP_CLIENT_ID")
    redirect_uri = payload.get("redirectUri")
    if not domain or not client_id or not redirect_uri or not payload.get("code"):
        raise ValueError("Cognito login is not configured")
    request = Request(
        f"{domain.rstrip('/')}/oauth2/token",
        data=urlencode({
            "grant_type": "authorization_code",
            "client_id": client_id,
            "code": payload["code"],
            "redirect_uri": redirect_uri,
            "code_verifier": payload.get("codeVerifier", ""),
        }).encode("utf-8"),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urlopen(request, timeout=15) as response:
        return json.load(response)


def refresh_cognito_session(payload):
    domain = os.environ.get("COGNITO_HOSTED_DOMAIN")
    client_id = os.environ.get("COGNITO_APP_CLIENT_ID")
    refresh_token = payload.get("refreshToken")
    if not domain or not client_id or not refresh_token:
        raise ValueError("Cognito refresh is not configured")
    request = Request(
        f"{domain.rstrip('/')}/oauth2/token",
        data=urlencode({
            "grant_type": "refresh_token",
            "client_id": client_id,
            "refresh_token": refresh_token,
        }).encode("utf-8"),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urlopen(request, timeout=15) as response:
        return json.load(response)


def revoke_cognito_session(payload):
    domain = os.environ.get("COGNITO_HOSTED_DOMAIN")
    client_id = os.environ.get("COGNITO_APP_CLIENT_ID")
    refresh_token = payload.get("refreshToken")
    if not domain or not client_id or not refresh_token:
        raise ValueError("Cognito revoke is not configured")
    request = Request(
        f"{domain.rstrip('/')}/oauth2/revoke",
        data=urlencode({"client_id": client_id, "token": refresh_token}).encode("utf-8"),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urlopen(request, timeout=15):
        return None


def create_order(order, user=None):
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
            **({"customerId": user["sub"]} if user else {}),
            "address": str(order["address"]),
            "contact": str(order["contact"]),
            "paymentMethod": str(order["paymentMethod"]),
            "cartItems": order["cartItems"],
            "status": "pending",
            **({"sessionId": str(order["sessionId"])} if order.get("sessionId") else {}),
            **({"hostId": str(order["hostId"])} if order.get("hostId") else {}),
        }
    )
    return order_id


def get_order(order_id, user=None):
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
    if user and order.get("customerId") != user["sub"]:
        raise PermissionError("Order does not belong to customer")
    return {"orderId": order["orderId"], "status": order.get("status", "pending")}


def get_order_settlement_details(order_id, user=None):
    table_name = os.environ.get("ORDERS_TABLE")
    if not table_name:
        return None
    region = os.environ.get("AWS_REGION") or os.environ.get(
        "AWS_DEFAULT_REGION", "ap-southeast-1"
    )
    orders_table = boto3.resource("dynamodb", region_name=region).Table(table_name)
    order = orders_table.get_item(Key={"orderId": order_id}).get("Item")
    if order is None:
        return None
    if user and order.get("customerId") != user["sub"]:
        raise PermissionError("Order does not belong to customer")

    result = {
        "orderId": order_id,
        "status": order.get("status", "pending"),
        "sessionId": order.get("sessionId"),
        "hostId": order.get("hostId"),
        "hasLiveAttribution": bool(order.get("sessionId") and order.get("hostId")),
    }

    settlements_table = _named_table("LIVE_SETTLEMENTS_TABLE")
    settlement = (
        settlements_table.get_item(Key={"settlementId": order_id}).get("Item")
        if settlements_table is not None
        else None
    )
    result["settlement"] = settlement
    result["hasSettlement"] = settlement is not None
    return result


def list_customer_orders(user):
    table_name = os.environ.get("ORDERS_TABLE")
    if not table_name:
        return []
    region = os.environ.get("AWS_REGION") or os.environ.get(
        "AWS_DEFAULT_REGION", "ap-southeast-1"
    )
    table = boto3.resource("dynamodb", region_name=region).Table(table_name)
    response = table.scan(
        FilterExpression="customerId = :customer_id",
        ExpressionAttributeValues={":customer_id": user["sub"]},
        ProjectionExpression="orderId, #status",
        ExpressionAttributeNames={"#status": "status"},
    )
    return response.get("Items", [])


def _named_table(variable):
    table_name = os.environ.get(variable)
    if not table_name:
        return None
    region = os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION", "ap-southeast-1")
    return boto3.resource("dynamodb", region_name=region).Table(table_name)


def _scan_table(variable):
    table = _named_table(variable)
    if table is None:
        return []
    items = []
    scan_kwargs = {}
    while True:
        response = table.scan(**scan_kwargs)
        items.extend(response.get("Items", []))
        if not response.get("LastEvaluatedKey"):
            return items
        scan_kwargs["ExclusiveStartKey"] = response["LastEvaluatedKey"]


def _can_host_live(user):
    groups = [group.lower() for group in user.get("groups", [])]
    return "queen" in groups or "bee" in groups


def _order_total(order):
    return sum(
        Decimal(str(item.get("price", 0))) * int(item.get("quantity", 1))
        for item in order.get("cartItems", [])
    )


def build_kpi_snapshot():
    orders = _scan_table("ORDERS_TABLE")
    settlements = _scan_table("LIVE_SETTLEMENTS_TABLE")
    drops = _scan_table("QUEEN_DROPS_TABLE")

    paid_orders = [order for order in orders if order.get("status") == "paid"]
    pending_orders = [order for order in orders if order.get("status") == "pending"]
    gmv = sum(_order_total(order) for order in paid_orders)
    customers = {
        str(order.get("customerId"))
        for order in orders
        if order.get("customerId")
    }
    commission_pool = sum(
        Decimal(str(item.get("queenCommission", 0)))
        + Decimal(str(item.get("beeCommission", 0)))
        for item in settlements
    )
    live_attributed_paid = [
        order for order in paid_orders if order.get("sessionId") and order.get("hostId")
    ]
    settled_ids = {str(item.get("orderId") or item.get("settlementId")) for item in settlements}
    settled_live_orders = [
        order for order in live_attributed_paid if str(order.get("orderId")) in settled_ids
    ]

    return {
        "catalogProducts": len(get_products()),
        "pendingOrders": len(pending_orders),
        "paidOrders": len(paid_orders),
        "gmv": float(gmv),
        "activeCustomers": len(customers),
        "commissionPool": float(commission_pool),
        "liveSessions": len(drops),
        "avgOrderValue": float(gmv / len(paid_orders)) if paid_orders else 0.0,
        "settlementRate": round(
            (len(settled_live_orders) / len(live_attributed_paid)) * 100, 2
        )
        if live_attributed_paid
        else 0.0,
        "nectarIssued": int(
            sum(int(item.get("nectarAward", 0)) for item in settlements)
        ),
    }


def _kpi_snapshots_table():
    return _named_table("KPI_SNAPSHOTS_TABLE")


def persist_kpi_snapshot(snapshot):
    table = _kpi_snapshots_table()
    if table is None:
        return
    table.put_item(
        Item={
            "snapshotId": str(uuid.uuid4()),
            "snapshotDate": time.strftime("%Y-%m-%d", time.gmtime()),
            "createdAt": int(time.time()),
            **snapshot,
        }
    )


def _default_trend(current):
    current_value = float(current)
    if current_value <= 0:
        return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    multipliers = [0.72, 0.8, 0.89, 0.94, 0.97, 1.0, 1.06]
    return [round(current_value * m, 2) for m in multipliers]


def _history_series(key, current):
    history = _scan_table("KPI_SNAPSHOTS_TABLE")
    if not history:
        return _default_trend(current)
    sorted_history = sorted(history, key=lambda item: int(item.get("createdAt", 0)))
    values = [
        float(item[key])
        for item in sorted_history
        if key in item and item.get(key) is not None
    ]
    values.append(float(current))
    if len(values) < 7:
        values = ([0.0] * (7 - len(values))) + values
    return [round(value, 2) for value in values[-7:]]


def build_kpi_trends(snapshot):
    return {
        "activeCustomers": _history_series("activeCustomers", snapshot["activeCustomers"]),
        "paidOrders": _history_series("paidOrders", snapshot["paidOrders"]),
        "commissionPool": _history_series("commissionPool", snapshot["commissionPool"]),
        "pendingOrders": _history_series("pendingOrders", snapshot["pendingOrders"]),
        "gmv": _history_series("gmv", snapshot["gmv"]),
        "settlementRate": _history_series("settlementRate", snapshot["settlementRate"]),
    }


def create_ivs_session(payload, user):
    region = os.environ.get("AWS_REGION") or os.environ.get("AWS_DEFAULT_REGION", "ap-southeast-1")
    ivs = boto3.client("ivs", region_name=region)
    channel = ivs.create_channel(
        name=str(payload["title"])[:128],
        latencyMode="LOW",
        type="STANDARD",
        authorized=False,
    )
    channel_info = channel["channel"]
    stream_key = ivs.get_stream_key(channelArn=channel_info["arn"])["streamKey"]
    session_id = str(uuid.uuid4())
    session = {
        "dropId": session_id,
        "title": str(payload["title"]),
        "product": str(payload.get("product", "Featured product")),
        "status": "scheduled",
        "hostId": user["sub"],
        "hostType": "queen" if "queen" in [group.lower() for group in user.get("groups", [])] else "bee",
        "viewerCount": 0,
        "streamUrl": channel_info["playbackUrl"],
        "ingestEndpoint": channel_info["ingestEndpoint"],
        "channelArn": channel_info["arn"],
        "streamKeyArn": stream_key["arn"],
    }
    table = _named_table("QUEEN_DROPS_TABLE")
    if table is not None:
        table.put_item(Item=session)
    return {key: value for key, value in session.items() if key not in ("channelArn", "streamKeyArn")}


def _profile_table():
    table_name = os.environ.get("PROFILE_TABLE")
    if not table_name:
        return None
    region = os.environ.get("AWS_REGION") or os.environ.get(
        "AWS_DEFAULT_REGION", "ap-southeast-1"
    )
    return boto3.resource("dynamodb", region_name=region).Table(table_name)


def get_profile(user):
    table = _profile_table()
    if table is None:
        return {"customerId": user["sub"], "name": "", "phone": "", "address": "", "payment": "", "wishlist": [], "rewards": {"points": 0, "coupons": []}, "subscriptions": [], "notifications": {"email": True, "sms": True, "delivery": True}, "linkedAccounts": []}
    item = table.get_item(Key={"customerId": user["sub"]}).get("Item")
    if item is None:
        return {"customerId": user["sub"], "name": "", "phone": "", "address": "", "payment": "", "wishlist": [], "rewards": {"points": 0, "coupons": []}, "subscriptions": [], "notifications": {"email": True, "sms": True, "delivery": True}, "linkedAccounts": []}
    item.pop("customerId", None)
    return item


def update_profile(payload, user):
    profile = get_profile(user)
    for field in ("name", "phone", "address", "payment"):
        if field in payload:
            profile[field] = str(payload[field]).strip()
    for field in ("wishlist", "rewards", "subscriptions", "notifications", "linkedAccounts"):
        if field in payload:
            profile[field] = payload[field]
    table = _profile_table()
    if table is not None:
        table.put_item(Item={"customerId": user["sub"], **profile})
    return {"customerId": user["sub"], **profile}


def redeem_reward(payload, user):
    profile = get_profile(user)
    rewards = profile.get("rewards", {"points": 0, "coupons": [], "transactions": []})
    points = int(rewards.get("points", 0))
    cost = int(payload.get("points", 100))
    if cost <= 0 or points < cost:
        raise ValueError("Insufficient reward points")
    rewards["points"] = points - cost
    rewards.setdefault("transactions", []).append({"type": "redeemed", "points": cost, "reward": payload.get("reward", "discount"), "createdAt": int(time.time())})
    return update_profile({"rewards": rewards}, user)


def update_order_status(order_id, status, payment_intent_id):
    table_name = os.environ.get("ORDERS_TABLE")
    if not table_name:
        return

    region = os.environ.get("AWS_REGION") or os.environ.get(
        "AWS_DEFAULT_REGION", "ap-southeast-1"
    )
    table = boto3.resource("dynamodb", region_name=region).Table(table_name)
    table.update_item(
        Key={"orderId": order_id},
        UpdateExpression="SET #status = :status, paymentIntentId = :payment_intent_id",
        ExpressionAttributeNames={"#status": "status"},
        ExpressionAttributeValues={
            ":status": status,
            ":payment_intent_id": payment_intent_id,
        },
        ConditionExpression="attribute_exists(orderId)",
    )


def settle_live_order(order_id):
    orders = _named_table("ORDERS_TABLE")
    settlements = _named_table("LIVE_SETTLEMENTS_TABLE")
    if orders is None or settlements is None:
        return None
    order = orders.get_item(Key={"orderId": order_id}).get("Item")
    if not order or not order.get("sessionId") or not order.get("hostId"):
        return None
    amount = sum(
        Decimal(str(item.get("price", 0))) * int(item.get("quantity", 1))
        for item in order.get("cartItems", [])
    )
    if amount <= 0:
        return None
    queen_rate = Decimal(os.environ.get("QUEEN_COMMISSION_RATE", "0.10"))
    bee_rate = Decimal(os.environ.get("BEE_COMMISSION_RATE", "0.10"))
    settlement = {
        "settlementId": order_id,
        "orderId": order_id,
        "sessionId": str(order["sessionId"]),
        "hostId": str(order["hostId"]),
        "amount": amount,
        "queenCommission": (amount * queen_rate).quantize(Decimal("0.01")),
        "beeCommission": (amount * bee_rate).quantize(Decimal("0.01")),
        "platformAmount": (amount * (1 - queen_rate - bee_rate)).quantize(Decimal("0.01")),
        "nectarAward": int(amount),
        "createdAt": int(time.time()),
    }
    try:
        settlements.put_item(Item=settlement, ConditionExpression="attribute_not_exists(settlementId)")
    except ClientError as error:
        if error.response.get("Error", {}).get("Code") != "ConditionalCheckFailedException":
            raise
        return None
    return settlement


def verify_stripe_signature(payload, signature_header):
    secret = os.environ.get("STRIPE_WEBHOOK_SECRET")
    if not secret or not signature_header:
        return False
    values = {}
    for item in signature_header.split(","):
        key, separator, value = item.partition("=")
        if separator:
            values.setdefault(key, []).append(value)
    try:
        timestamp = int(values["t"][0])
        signatures = values["v1"]
    except (KeyError, ValueError):
        return False
    if abs(time.time() - timestamp) > 300:
        return False
    signed_payload = f"{timestamp}.".encode("utf-8") + payload
    expected = hmac.new(
        secret.encode("utf-8"), signed_payload, hashlib.sha256
    ).hexdigest()
    return any(hmac.compare_digest(expected, signature) for signature in signatures)


_processed_events = set()


def process_stripe_event(event):
    event_id = event.get("id")
    if not event_id or event_id in _processed_events:
        return False

    event_type = event.get("type")
    data = event.get("data", {}).get("object", {})
    if event_type == "checkout.session.completed":
        order_id = data.get("metadata", {}).get("orderId")
        if order_id and data.get("payment_status") == "paid":
            update_order_status(order_id, "paid", data.get("payment_intent", ""))
            settle_live_order(order_id)
            if not mark_event_processed(event_id):
                return False
            _processed_events.add(event_id)
            return True
    if not mark_event_processed(event_id):
        return False
    _processed_events.add(event_id)
    return False


def mark_event_processed(event_id):
    table_name = os.environ.get("EVENTS_TABLE")
    if not table_name:
        _processed_events.add(event_id)
        return True

    region = os.environ.get("AWS_REGION") or os.environ.get(
        "AWS_DEFAULT_REGION", "ap-southeast-1"
    )
    try:
        table = boto3.resource("dynamodb", region_name=region).Table(table_name)
        try:
            table.put_item(
                Item={"eventId": event_id, "processedAt": int(time.time())},
                ConditionExpression="attribute_not_exists(eventId)",
            )
        except ClientError as error:
            if error.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException":
                return False
            raise
    except Exception as error:
        logger.warning(
            "Stripe event dedupe storage unavailable for %s; using in-memory fallback: %s",
            event_id,
            error,
        )
        _processed_events.add(event_id)
        return True

    _processed_events.add(event_id)
    return True


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


def verify_payment_intent(payment):
    secret_key = os.environ.get("STRIPE_SECRET_KEY")
    if not secret_key:
        raise RuntimeError("Stripe is not configured")
    payment_intent_id = payment.get("paymentIntentId")
    order_id = payment.get("orderId")
    if not payment_intent_id or not order_id:
        raise ValueError("Missing payment verification field")

    request = Request(
        f"https://api.stripe.com/v1/payment_intents/{payment_intent_id}",
        headers={"Authorization": f"Bearer {secret_key}"},
        method="GET",
    )
    with urlopen(request, timeout=15) as response:
        stripe_payment = json.load(response)

    status = stripe_payment.get("status")
    if stripe_payment.get("metadata", {}).get("orderId") != order_id:
        raise ValueError("Payment intent does not belong to order")
    if status == "succeeded":
        update_order_status(order_id, "paid", payment_intent_id)

    return {
        "orderId": order_id,
        "paymentIntentId": payment_intent_id,
        "status": status,
        "orderStatus": "paid" if status == "succeeded" else "pending",
    }


def create_checkout_session(order):
    secret_key = os.environ.get("STRIPE_SECRET_KEY")
    if not secret_key:
        raise RuntimeError("Stripe is not configured")
    order_id = order.get("orderId")
    cart_items = order.get("cartItems")
    if not order_id or not cart_items:
        raise ValueError("Missing checkout field")

    live_session_id = order.get("sessionId")
    live_host_id = order.get("hostId")
    if not live_session_id or not live_host_id:
        orders_table = _named_table("ORDERS_TABLE")
        if orders_table is not None:
            stored = orders_table.get_item(Key={"orderId": order_id}).get("Item", {})
            live_session_id = live_session_id or stored.get("sessionId")
            live_host_id = live_host_id or stored.get("hostId")

    form = {
        "mode": "payment",
        "success_url": os.environ.get(
            "CHECKOUT_SUCCESS_URL",
            "http://localhost:8080/#/confirmation?session_id={CHECKOUT_SESSION_ID}",
        ),
        "cancel_url": os.environ.get(
            "CHECKOUT_CANCEL_URL", "http://localhost:8080/#/checkout"
        ),
        "metadata[orderId]": order_id,
    }
    if live_session_id:
        form["metadata[sessionId]"] = str(live_session_id)
    if live_host_id:
        form["metadata[hostId]"] = str(live_host_id)
    for index, item in enumerate(cart_items):
        prefix = f"line_items[{index}]"
        form[f"{prefix}[price_data][currency]"] = "myr"
        form[f"{prefix}[price_data][product_data][name]"] = str(item["name"])
        form[f"{prefix}[price_data][unit_amount]"] = str(
            int(round(float(item["price"]) * 100))
        )
        form[f"{prefix}[quantity]"] = str(int(item.get("quantity", 1)))

    request = Request(
        "https://api.stripe.com/v1/checkout/sessions",
        data=urlencode(form).encode("utf-8"),
        headers={"Authorization": f"Bearer {secret_key}"},
        method="POST",
    )
    with urlopen(request, timeout=15) as response:
        stripe_session = json.load(response)
    return {"sessionId": stripe_session["id"], "url": stripe_session["url"]}


def verify_checkout_session(payment):
    secret_key = os.environ.get("STRIPE_SECRET_KEY")
    if not secret_key:
        raise RuntimeError("Stripe is not configured")
    session_id = payment.get("sessionId")
    if not session_id:
        raise ValueError("Missing checkout session ID")

    request = Request(
        f"https://api.stripe.com/v1/checkout/sessions/{session_id}",
        headers={"Authorization": f"Bearer {secret_key}"},
        method="GET",
    )
    with urlopen(request, timeout=15) as response:
        session = json.load(response)

    order_id = session.get("metadata", {}).get("orderId")
    if not order_id:
        raise ValueError("Checkout session has no order")
    paid = session.get("payment_status") == "paid"
    payment_intent_id = session.get("payment_intent") or ""
    if paid:
        update_order_status(order_id, "paid", payment_intent_id)
        settle_live_order(order_id)

    return {
        "orderId": order_id,
        "sessionId": session_id,
        "status": session.get("payment_status", "unpaid"),
        "orderStatus": "paid" if paid else "pending",
    }


if __name__ == "__main__":
    os.chdir(os.environ.get("WEB_ROOT", "/app/build/web"))
    port = int(os.environ.get("PORT", "80"))
    server = ThreadingHTTPServer(("0.0.0.0", port), AppHandler)
    print(f"Serving Flutter web and catalog API on port {port}", flush=True)
    server.serve_forever()
