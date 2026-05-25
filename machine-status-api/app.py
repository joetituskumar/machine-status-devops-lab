from fastapi import FastAPI
from datetime import datetime

app = FastAPI(title="Machine Status API")

@app.get("/health")
def health():
    return {"status": "ok", "service": "machine-status-api"}

@app.get("/version")
def version():
    return {"version": "1.0.0", "deployed_at": datetime.utcnow().isoformat()}

@app.get("/machines")
def machines():
    return {
        "machines": [
            {"id": "CNC-01", "status": "running", "temperature": 67},
            {"id": "PRESS-02", "status": "maintenance", "temperature": 40},
            {"id": "ROBOT-03", "status": "idle", "temperature": 51}
        ]
    }
