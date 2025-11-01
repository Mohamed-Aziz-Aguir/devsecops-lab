import anyio
from httpx import AsyncClient
from app.main import app

async def _post(client, url, json):
    return await client.post(url, json=json)

async def _get(client, url):
    return await client.get(url)

@anyio.run
async def test_health_and_hello():
    async with AsyncClient(app=app, base_url="http://test") as client:
        r = await _get(client, "/health")
        assert r.status_code == 200
        assert r.json()["status"] == "ok"
        r2 = await _post(client, "/hello", {"name": "Aziz"})
        assert r2.status_code == 200
        assert r2.json()["message"] == "Hello, Aziz!"
