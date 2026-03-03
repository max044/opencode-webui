import beam

# Define persistent workspace volume
workspace_volume = beam.Volume(name="opencode-workspace", mount_path="/home/opencode")

# OpenCode WebUI runs a continuous server and needs ports exposed,
# so we use a Pod rather than a serverless RestAPI endpoint.
app = beam.Pod(
    name="opencode-webui",
    cpu=4,  # Increased for better performance as a "Lovable" equivalent
    memory="8Gi",
    volumes=[workspace_volume],
    # Build directly on Beam using the local Dockerfile
    image=beam.Image(dockerfile="Dockerfile"),
    # Explicitly set the entrypoint to ensure the start script runs
    entrypoint=["bash", "/usr/local/bin/start.sh"],
    # Expose the OpenCode WebUI port and preview ports
    ports=[4096, 3000, 5173, 8000, 8080],
    # Pass environment variables (Secrets from Beam dashboard are automatically injected)
    env={"PORT": "4096", "OPENCODE_DATA_DIR": "/home/opencode/workspace/.opencode"},
)

app.deploy()
