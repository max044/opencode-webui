import os
import json
import re

from beam import Image, PythonVersion, asgi
from fastapi import FastAPI, Request
from fastapi.responses import FileResponse, Response
from fastapi.staticfiles import StaticFiles

app = FastAPI()

build_dir = os.path.join(os.path.dirname(__file__), "platform/frontend/build")


@app.get("/_app/env.js")
async def serve_env_js():
    """
    Dynamically serves the SvelteKit env.js file, overriding values with
    environment variables present on the host (e.g., Beam deployment).
    """
    env_path = os.path.join(build_dir, "_app", "env.js")
    if os.path.exists(env_path):
        with open(env_path, "r") as f:
            content = f.read()
            match = re.search(r"export const env=(.*)", content)
            if match:
                try:
                    env_dict = json.loads(match.group(1))
                    # Override with any matching actual environment variables
                    for key in env_dict.keys():
                        if key in os.environ:
                            env_dict[key] = os.environ[key]

                    new_content = f"export const env={json.dumps(env_dict)}"
                    return Response(
                        content=new_content, media_type="application/javascript"
                    )
                except json.JSONDecodeError:
                    pass

    # Fallback to serving the static file
    return (
        FileResponse(env_path)
        if os.path.exists(env_path)
        else Response(status_code=404)
    )


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
    secrets=[
        "PUBLIC_ORCHESTRATOR_URL",
        "PUBLIC_SUPABASE_URL",
        "PUBLIC_SUPABASE_ANON_KEY",
    ],
    authorized=False,
    concurrent_requests=1000,
)
def dashboard():
    return app
