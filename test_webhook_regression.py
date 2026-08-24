import sys
from pathlib import Path
from urllib.parse import unquote_plus

sys.path.insert(0, str(Path(__file__).resolve().parent / "backend"))

import server


def test_mark_event_processed_falls_back_when_table_is_unavailable(monkeypatch):
    server._processed_events.clear()
    monkeypatch.setenv("EVENTS_TABLE", "frenzybees-staging-events")

    def fake_resource(*args, **kwargs):
        raise RuntimeError("DynamoDB unavailable")

    monkeypatch.setattr(server.boto3, "resource", fake_resource)

    assert server.mark_event_processed("evt_123") is True
    assert "evt_123" in server._processed_events


def test_process_stripe_event_handles_checkout_event_without_durable_storage(monkeypatch):
    server._processed_events.clear()
    monkeypatch.setenv("EVENTS_TABLE", "frenzybees-staging-events")
    monkeypatch.setattr(server, "update_order_status", lambda *args, **kwargs: None)

    def fake_resource(*args, **kwargs):
        raise RuntimeError("DynamoDB unavailable")

    monkeypatch.setattr(server.boto3, "resource", fake_resource)

    event = {
        "id": "evt_456",
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "metadata": {"orderId": "order_123"},
                "payment_status": "paid",
                "payment_intent": "pi_123",
            }
        },
    }

    assert server.process_stripe_event(event) is True
    assert "evt_456" in server._processed_events


def test_process_stripe_event_triggers_live_settlement_for_paid_checkout(monkeypatch):
    server._processed_events.clear()
    monkeypatch.setattr(server, "mark_event_processed", lambda _event_id: True)
    update_calls = []
    settle_calls = []
    monkeypatch.setattr(
        server,
        "update_order_status",
        lambda order_id, status, payment_intent: update_calls.append(
            (order_id, status, payment_intent)
        ),
    )
    monkeypatch.setattr(server, "settle_live_order", lambda order_id: settle_calls.append(order_id))

    event = {
        "id": "evt_settle_1",
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "metadata": {"orderId": "order_live_1"},
                "payment_status": "paid",
                "payment_intent": "pi_live_1",
            }
        },
    }

    assert server.process_stripe_event(event) is True
    assert update_calls == [("order_live_1", "paid", "pi_live_1")]
    assert settle_calls == ["order_live_1"]


def test_checkout_session_includes_live_metadata_from_stored_order(monkeypatch):
    monkeypatch.setenv("STRIPE_SECRET_KEY", "sk_test")

    class FakeOrdersTable:
        def get_item(self, Key):
            assert Key["orderId"] == "order_live_2"
            return {"Item": {"sessionId": "drop_2", "hostId": "queen_2"}}

    monkeypatch.setattr(
        server,
        "_named_table",
        lambda name: FakeOrdersTable() if name == "ORDERS_TABLE" else None,
    )

    captured = {}

    class FakeResponse:
        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return False

        def read(self):
            return b'{"id":"cs_test_live","url":"https://checkout.stripe.com/live"}'

    def fake_urlopen(request, timeout=15):
        captured["body"] = request.data.decode("utf-8")
        return FakeResponse()

    monkeypatch.setattr(server, "urlopen", fake_urlopen)

    result = server.create_checkout_session(
        {
            "orderId": "order_live_2",
            "cartItems": [{"name": "Sneakers", "price": 120, "quantity": 1}],
        }
    )

    body = unquote_plus(captured["body"])
    assert "metadata[sessionId]=drop_2" in body
    assert "metadata[hostId]=queen_2" in body
    assert result["sessionId"] == "cs_test_live"


def test_get_order_settlement_details_returns_attribution_and_settlement(monkeypatch):
    class FakeTable:
        def __init__(self, item):
            self.item = item

        def get_item(self, Key):
            return {"Item": self.item}

    class FakeDynamoResource:
        def Table(self, _name):
            return FakeTable(
                {
                    "orderId": "order_live_3",
                    "customerId": "customer_3",
                    "status": "paid",
                    "sessionId": "drop_3",
                    "hostId": "queen_3",
                }
            )

    monkeypatch.setenv("ORDERS_TABLE", "orders")
    monkeypatch.setattr(server.boto3, "resource", lambda *args, **kwargs: FakeDynamoResource())
    monkeypatch.setattr(
        server,
        "_named_table",
        lambda name: FakeTable(
            {
                "settlementId": "order_live_3",
                "orderId": "order_live_3",
                "sessionId": "drop_3",
                "hostId": "queen_3",
                "amount": 120,
            }
        )
        if name == "LIVE_SETTLEMENTS_TABLE"
        else None,
    )

    result = server.get_order_settlement_details(
        "order_live_3", {"sub": "customer_3", "groups": []}
    )
    assert result["hasLiveAttribution"] is True
    assert result["hasSettlement"] is True
    assert result["settlement"]["orderId"] == "order_live_3"


def test_get_order_settlement_details_rejects_wrong_customer(monkeypatch):
    class FakeTable:
        def get_item(self, Key):
            return {
                "Item": {
                    "orderId": Key["orderId"],
                    "customerId": "owner",
                    "status": "paid",
                }
            }

    class FakeDynamoResource:
        def Table(self, _name):
            return FakeTable()

    monkeypatch.setenv("ORDERS_TABLE", "orders")
    monkeypatch.setattr(server.boto3, "resource", lambda *args, **kwargs: FakeDynamoResource())

    try:
        server.get_order_settlement_details("order_unauthorized", {"sub": "other", "groups": []})
        assert False, "Expected PermissionError"
    except PermissionError:
        assert True


def test_build_kpi_snapshot_aggregates_orders_and_settlements(monkeypatch):
    orders = [
        {
            "orderId": "order_1",
            "customerId": "cust_1",
            "status": "paid",
            "cartItems": [{"price": 100, "quantity": 2}],
            "sessionId": "drop_1",
            "hostId": "queen_1",
        },
        {
            "orderId": "order_2",
            "customerId": "cust_2",
            "status": "pending",
            "cartItems": [{"price": 50, "quantity": 1}],
        },
    ]
    settlements = [
        {
            "settlementId": "order_1",
            "orderId": "order_1",
            "queenCommission": 20,
            "beeCommission": 20,
            "nectarAward": 200,
        }
    ]
    drops = [{"dropId": "drop_1"}, {"dropId": "drop_2"}]

    monkeypatch.setattr(
        server,
        "_scan_table",
        lambda name: orders
        if name == "ORDERS_TABLE"
        else settlements
        if name == "LIVE_SETTLEMENTS_TABLE"
        else drops
        if name == "QUEEN_DROPS_TABLE"
        else [],
    )
    monkeypatch.setattr(server, "get_products", lambda: [{"name": "p1"}, {"name": "p2"}])

    snapshot = server.build_kpi_snapshot()

    assert snapshot["catalogProducts"] == 2
    assert snapshot["pendingOrders"] == 1
    assert snapshot["paidOrders"] == 1
    assert snapshot["gmv"] == 200.0
    assert snapshot["activeCustomers"] == 2
    assert snapshot["commissionPool"] == 40.0
    assert snapshot["liveSessions"] == 2
    assert snapshot["settlementRate"] == 100.0
    assert snapshot["nectarIssued"] == 200


def test_build_kpi_trends_prefers_snapshot_history(monkeypatch):
    history = [
        {"createdAt": 1, "gmv": 100, "paidOrders": 1, "activeCustomers": 1, "commissionPool": 10, "pendingOrders": 1, "settlementRate": 90},
        {"createdAt": 2, "gmv": 120, "paidOrders": 2, "activeCustomers": 2, "commissionPool": 20, "pendingOrders": 1, "settlementRate": 92},
        {"createdAt": 3, "gmv": 140, "paidOrders": 3, "activeCustomers": 3, "commissionPool": 30, "pendingOrders": 1, "settlementRate": 95},
    ]
    monkeypatch.setattr(server, "_scan_table", lambda name: history if name == "KPI_SNAPSHOTS_TABLE" else [])

    trends = server.build_kpi_trends(
        {
            "gmv": 160,
            "paidOrders": 4,
            "activeCustomers": 4,
            "commissionPool": 40,
            "pendingOrders": 1,
            "settlementRate": 96,
        }
    )

    assert trends["gmv"][-1] == 160.0
    assert len(trends["gmv"]) == 7
    assert trends["settlementRate"][-1] == 96.0
