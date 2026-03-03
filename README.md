# OpenCode Platform

A **cloud-native development platform** that provisions isolated coding
environments on demand. Users can create projects from a dashboard, each getting
their own Neon database, GitHub repository, and a Beam Sandbox running OpenCode.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Beam.cloud                           │
│                                                         │
│  ┌──────────────────┐    ┌──────────────────────────┐  │
│  │  Dashboard       │    │  Orchestrator            │  │
│  │  (frontend_      │───▶│  (app.py)                │  │
│  │  server.py)      │    │  FastAPI + Beam ASGI      │  │
│  │  SvelteKit SPA   │    └────────────┬─────────────┘  │
│  └──────────────────┘                 │                 │
│                                       ▼                 │
│                        ┌─────────────────────────┐     │
│                        │  Beam Sandbox (per user) │     │
│                        │  OpenCode instance       │     │
│                        └─────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
         │                        │
         ▼                        ▼
  Supabase (Auth +         Neon DB + GitHub
  project metadata)        (per project)
```

## Live URLs

| Service          | URL                                                       |
| ---------------- | --------------------------------------------------------- |
| **Dashboard**    | `https://opencode-dashboard-1b155fd-v4.app.beam.cloud`    |
| **Orchestrator** | `https://opencode-orchestrator-8dac31e-v6.app.beam.cloud` |

## Project Structure

```
opencode-webui/
├── app.py                   # Beam Orchestrator (FastAPI ASGI)
├── frontend_server.py       # Beam Dashboard (FastAPI static files)
├── platform/
│   └── frontend/            # SvelteKit dashboard
│       ├── src/
│       │   └── routes/      # Login, Dashboard pages
│       ├── build/           # Pre-built static files (git-ignored)
│       └── .env             # Frontend env (Supabase + Orchestrator URLs)
└── supabase/
    └── migrations/          # DB schema (profiles + projects tables)
```

## Prerequisites

1. [Beam.cloud](https://www.beam.cloud/) account + CLI installed:
   ```bash
   curl https://raw.githubusercontent.com/slai-labs/get-beam/main/get-beam.sh -sSfL | sh
   beam login
   ```

2. [Supabase](https://supabase.com/) project with the schema applied (see below)

3. Add the following **Beam Secrets** in your
   [Beam Dashboard](https://www.beam.cloud/dashboard/settings/secrets):
   - `SUPABASE_URL` — Your Supabase project URL
   - `SUPABASE_SERVICE_ROLE_KEY` — Supabase service role key
   - `NEON_API_KEY` — [Neon](https://neon.tech) API key for DB provisioning
   - `GH_PAT` — GitHub Personal Access Token for repo creation

## Supabase Setup

Run this SQL in your
[Supabase SQL Editor](https://supabase.com/dashboard/project/_/sql):

```sql
-- Profiles table (stores user API keys)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  full_name TEXT,
  github_token TEXT,
  neon_api_key TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Projects table
CREATE TABLE public.projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) NOT NULL,
  name TEXT NOT NULL,
  sandbox_id TEXT,
  status TEXT DEFAULT 'creating',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view own projects" ON public.projects FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own projects" ON public.projects FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own projects" ON public.projects FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own projects" ON public.projects FOR DELETE USING (auth.uid() = user_id);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name) VALUES (new.id, new.raw_user_meta_data->>'full_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

## Frontend Configuration

Update `platform/frontend/.env`:

```env
PUBLIC_SUPABASE_URL=https://<your-project>.supabase.co
PUBLIC_SUPABASE_ANON_KEY=<your-anon-key>
PUBLIC_ORCHESTRATOR_URL=https://opencode-orchestrator-8dac31e-v6.app.beam.cloud
```

## Deployment

### Deploy Everything

```bash
# 1. Build the SvelteKit frontend (must be done before every frontend deploy)
cd platform/frontend && npm run build && cd ../..

# 2. Deploy the dashboard (static files served by FastAPI)
uv run beam deploy frontend_server.py:dashboard

# 3. Deploy the orchestrator
uv run beam deploy app.py:web_server
```

### Deploy Orchestrator Only

```bash
uv run beam deploy app.py:web_server
```

### Deploy Frontend Only

```bash
cd platform/frontend && npm run build && cd ../..
uv run beam deploy frontend_server.py:dashboard
```

## How It Works

1. User signs up/logs in via **Magic Link** (Supabase Auth)
2. User clicks **"New Project"** on the dashboard
3. Dashboard calls the **Orchestrator** (`POST /projects/create`)
4. Orchestrator:
   - Fetches user's API keys from Supabase `profiles`
   - Provisions a **Neon database** for the project
   - Creates a private **GitHub repository**
   - Registers the project in Supabase `projects`
   - Spawns a **Beam Sandbox** with OpenCode pre-configured

## Local Development

```bash
# Start the frontend dev server
cd platform/frontend && npm run dev
# → http://localhost:5173

# Run the orchestrator locally
uv run uvicorn app:api --reload --port 8000
```

## Support

- **OpenCode**: https://github.com/opencodeinc/opencode
- **Beam.cloud Docs**: https://docs.beam.cloud
- **Supabase Docs**: https://supabase.com/docs
