import beam

# Define persistent workspace volume
workspace_volume = beam.Volume(name="opencode-workspace", mount_path="/home/opencode")

# OpenCode WebUI runs a continuous server and needs ports exposed,
# so we use a Pod rather than a serverless RestAPI endpoint.
app = beam.Pod(
    name="opencode-webui",
    cpu=2,
    memory="4Gi",
    volumes=[workspace_volume],
    # Use the image directly from GHCR since it's built by GitHub Actions
    # Users should replace YOUR_GITHUB_USER with their actual github username
    image=beam.Image(base_image="ghcr.io/max044/opencode-webui:latest"),
    # Expose the OpenCode WebUI port (4096)
    # Expose common preview ports (e.g., 3000 for React/Svelte, 5173 for Vite, 8000 for Python)
    ports=[4096, 3000, 5173, 8000, 8080],
)
