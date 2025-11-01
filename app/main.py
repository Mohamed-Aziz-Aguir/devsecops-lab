from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="DevSecOps Lab API", version="1.0.0")

class HelloReq(BaseModel):
    name: str

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/hello")
def hello(req: HelloReq):
    name = req.name.strip()[:64]
    return {"message": f"Hello, {name}!"}
