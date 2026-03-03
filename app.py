import beam
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
import os
import httpx
from supabase import create_client, Client, ClientOptions

# --- Configuration & Images ---

# The Sandbox Image: Environment where individual user projects will run
# It needs Node.js, Python, and OpenCode WebUI pre-installed
sandbox_image = beam.Image(
    python_version="python3.11",
    commands=[
        "apt-get update && apt-get install -y curl git",
        "curl -fsSL https://deb.nodesource.com/setup_20.x | bash -",
        "apt-get install -y nodejs",
        # Install OpenCode dependencies if needed, or pull from GHCR
    ],
)

# The Orchestrator Image: Runs the FastAPI app that creates projects
orchestrator_image = beam.Image(
    python_version="python3.11",
    python_packages=[
        "fastapi",
        "httpx",
        "uvicorn",
        "supabase>=2.0.0",
        "websockets>=13.0",
    ],
)

# --- Integrations ---


async def provision_neon_db(api_key: str, project_name: str):
    """Provisions a new Neon database for the project"""
    async with httpx.AsyncClient() as client:
        # 1. Create a project
        resp = await client.post(
            "https://console.neon.tech/api/v2/projects",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            json={"project": {"name": project_name}},
        )
        if resp.status_code >= 400:
            return None
        return resp.json()["project"]["id"]


async def create_github_repo(token: str, repo_name: str):
    """Creates a new private GitHub repository"""
    async with httpx.AsyncClient() as client:
        resp = await client.post(
            "https://api.github.com/user/repos",
            headers={
                "Authorization": f"token {token}",
                "Accept": "application/vnd.github.v3+json",
            },
            json={"name": repo_name, "private": True},
        )
        if resp.status_code >= 400:
            return None
        return resp.json()["html_url"]


# --- FastAPI Orchestrator ---

api = FastAPI(title="OpenCode Orchestrator")

api.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Supabase Client for metadata management
def get_supabase(auth_header: str = None):
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        return None

    if auth_header:
        return create_client(
            url, key, options=ClientOptions(headers={"Authorization": auth_header})
        )
    return create_client(url, key)


@api.get("/")
async def health():
    return {"status": "alive"}


@api.post("/projects/create")
async def create_project(request: Request):
    """
    1. Fetch user keys from Supabase
    2. Provision Neon DB
    3. Create GitHub Repo
    4. Register project in Supabase
    """
    body = await request.json()
    user_id = body.get("user_id")
    project_name = body.get("name")

    if not user_id or not project_name:
        raise HTTPException(status_code=400, detail="Missing user_id or name")

    # 1. Fetch user profile keys
    auth_header = request.headers.get("Authorization")
    sb_client = get_supabase(auth_header)
    if not sb_client:
        raise HTTPException(
            status_code=500, detail="Orchestrator is missing Supabase credentials."
        )

    user_profile = (
        sb_client.table("profiles")
        .select("*")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )

    neon_key = None
    github_token = None
    if user_profile and user_profile.data:
        neon_key = user_profile.data.get("neon_api_key")
        github_token = user_profile.data.get("github_token")

    if not neon_key or not github_token:
        # Fallback to system keys if user hasn't provided their own
        neon_key = neon_key or os.environ.get("NEON_API_KEY")
        github_token = github_token or os.environ.get("GH_PAT")

    # 2. Provision Neon DB
    neon_project_id = await provision_neon_db(neon_key, f"opencode-{project_name}")

    # 3. Create GitHub Repo
    repo_url = await create_github_repo(github_token, project_name)

    # 4. Create entry in Supabase 'projects' table
    new_project = {
        "user_id": user_id,
        "name": project_name,
        "github_repo": repo_url,
        "status": "creating",
    }
    res = sb_client.table("projects").insert(new_project).execute()
    project_id = res.data[0]["id"]

    # 5. Spawn Beam Sandbox for the project
    try:
        sb = beam.Sandbox(
            image=sandbox_image,
            name=f"project-{project_id}",
            cpu=1,
            memory=1024,
            keep_warm_seconds=300,
            env={
                "OPENCODE_GITHUB_URL": repo_url,
                "DATABASE_URL": f"postgresql://postgres:postgres@.../{neon_project_id}",
                "PORT": "4096",
            },
        ).create()

        sandbox_url = sb.expose_port(4096)

        # 6. Update project with sandbox info
        sb_client.table("projects").update(
            {"status": "active", "sandbox_id": sb.sandbox_id()}
        ).eq("id", project_id).execute()

        return {
            "project": res.data[0],
            "sandbox_url": sandbox_url,
            "message": "Project created successfully",
        }
    except Exception as e:
        sb_client.table("projects").update({"status": "error"}).eq(
            "id", project_id
        ).execute()
        raise HTTPException(
            status_code=500, detail=f"Sandbox creation failed: {str(e)}"
        ) from e


# --- Deployment ---


@beam.asgi(
    name="opencode-orchestrator",
    image=orchestrator_image,
    volumes=[beam.Volume(name="orchestrator-data", mount_path="/data")],
    secrets=[
        "SUPABASE_URL",
        "SUPABASE_SERVICE_ROLE_KEY",
        "NEON_API_KEY",
        "GH_PAT",
    ],
    authorized=False,
)
def web_server():
    return api
