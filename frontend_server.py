import os

from beam import Image, PythonVersion, asgi
from fastapi import FastAPI, Request
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

app = FastAPI()

build_dir = os.path.join(os.path.dirname(__file__), "platform/frontend/build")

# Mount the _app/immutable assets (JS/CSS bundles)
app.mount(
    "/_app",
    StaticFiles(directory=os.path.join(build_dir, "_app")),
    name="app_assets",
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/{full_path:path}")
async def serve_svelte_app(full_path: str, request: Request):
    # Serve any root-level static files (favicon, robots.txt, etc.)
    file_path = os.path.join(build_dir, full_path)
    if os.path.isfile(file_path):
        return FileResponse(file_path)

    # SPA fallback: serve index.html for all routes (client-side routing)
    index_path = os.path.join(build_dir, "index.html")
    return FileResponse(index_path)


image = Image(
    python_version=PythonVersion.Python311,
    python_packages=["fastapi", "uvicorn"],
)


@asgi(
    name="opencode-dashboard",
    image=image,
    authorized=False,
    concurrent_requests=1000,
)
def dashboard():
    return app
