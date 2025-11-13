# tests/test_smoke.py
from app import app

def test_index_returns_200():
    client = app.test_client()
    resp = client.get("/")
    assert resp.status_code == 200
