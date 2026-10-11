# Deployment

At the end you will know where each of the six images runs, what to set in
GitHub and on the home lab, and how to verify and roll back.

## What runs where

| Image | Runs on | Started by |
|---|---|---|
| `job-scout` | GitHub Actions runner | `job-scout daily trends` workflow (11:00 UTC) |
| `job-pilot` | GitHub Actions runner | `job-pilot daily digest` workflow (after trends) |
| `agent-job-matcher` | home lab | `docker compose` (port 6010) |
| `agent-job-matcher-agent-service` | home lab | `docker compose` (port 6011) |
| `agent-job-matcher-playground` | home lab | `docker compose` (port 6012) |
| `agent-job-matcher-openapi-docs` | home lab | `docker compose` (port 6013) |

The home lab's compose file is in a separate private repo and pulls these
images by name. **Image names never change**, so a rebuild needs only a pull.

`chat-demo` in `job-matcher/docker-compose.yaml` uses
`ghcr.io/senthilsweb/mcp-chat-client`, which is built from the separate
`mcp-chat-client` repo, not from here.

## How images are built

| Workflow | Triggers | Produces |
|---|---|---|
| `job-scout-image.yml` | push to main touching `job-scout/tools`, `templates`, `docker`, `Dockerfile` or `config.yaml` | `job-scout` |
| `job-pilot-image.yml` | push touching `job-pilot/` or `job-scout/config.yaml`: tests on every push, image only on main | `job-pilot` |
| `job-matcher-images.yml` | push to main touching `job-matcher/**` (not specs or markdown), tags `job-matcher-v*`, PRs build without pushing | the four `agent-job-matcher*` images (only the ones whose paths changed) |

Docker builds run from the repo root because job-pilot's image also copies
`job-scout/config.yaml`.

## One-time GitHub setup

### Secrets

| Secret | Used by | Purpose |
|---|---|---|
| `JOBMATCH_API_BASE`, `JOBMATCH_AGENT_BASE` | pilot, health | public URLs of the home-lab API and agent |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS` | pilot, health | Gmail SMTP (app password) |
| `DIGEST_FROM`, `DIGEST_TO` | pilot, health | sender and recipient(s); `DIGEST_TO` may be comma-separated |
| `LETTERHEAD_PHONE` | pilot | phone for letters and resumes (repo copies are scrubbed) |
| `TYPESAFE_API_KEY` | pilot, health | Jev key (console.typesafe.ai/keys) |
| `LANGSMITH_API_KEY` | pilot | optional; tracing is off when empty |
| `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_HEADERS` | pilot, health | OpenObserve; must be reachable from GitHub (a `localhost` value will not work) |
| `PHOENIX_COLLECTOR_ENDPOINT`, `PHOENIX_CLIENT_HEADERS` | pilot, health | Arize; endpoint is the base `https://otlp.arize.com`, **without** `/v1` |

Secrets are write-only in GitHub. To move them between repos, use a one-off
workflow in the source repo that reads them and runs `gh secret set` with a
short-lived token.

### Variables

| Variable | Values | Default |
|---|---|---|
| `JEV_MODE` | `off`, `shadow`, `enforce` | `off` |

A manual run can override it with the `jev_mode` input.

### GHCR package access

For each of the six packages: **Package settings → Manage Actions access →
Add Repository → `job-agents` → Write**. Without this the first push fails
with `permission_denied`.

### Pages

Settings → Pages → Source: GitHub Actions. The single deployer is
`site.yml`; the site resolves at `https://www.senthilsweb.com/job-agents/`.

## Baseline continuity

job-pilot compares today's parquet against the `trends/YYYYMMDD` tag of its
last successful run, resolved from this repo's tags. A new repo needs at
least one tag on or before yesterday:

```bash
git tag trends/YYYYMMDD <commit-with-that-parquet> && git push origin trends/YYYYMMDD
```

A run that finds no tag within 8 days fails loudly rather than guess.

## Deploy the home lab

```bash
docker compose pull
docker compose up -d
curl -fsS https://jobmatch-api.nathansweb.com/health
curl -fsS https://jobmatch-agent.nathansweb.com/health
```

## Verify after any deploy

1. Actions → `job-pilot health check` → Run workflow with `force_email=true`
   (and `trace_probe=true` to send one real span). All probes should be UP
   and an email should arrive.
2. Actions → `job-pilot daily digest` → Run workflow. The log line
   `jev: mode=… asked=… errors=0` confirms the gate; the final line reports
   `new, matched, PDFs, failures`.
3. Check all six packages show a fresh `latest`.

## Roll out and roll back Jev

| Step | Setting |
|---|---|
| Observe | `JEV_MODE=shadow`: Jev runs, nothing changes, disagreements in the digest |
| Decide | `JEV_MODE=enforce` after reviewing disagreements |
| Roll back | `JEV_MODE=off` (or unset the variable): byte-for-byte the string rules |

No code change or redeploy is needed for any of these.

## Roll back an image

Pull a previous digest or tag on the home lab (`docker compose pull` with the
tag pinned in the compose file). For job-pilot, revert the commit; the image
rebuilds on main.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Run is green but nothing matched | home-lab API behind the tunnel returned 502; check the health-check email |
| `no trends tag found within 8 days` | missing baseline tags (see Baseline continuity) |
| `permission_denied` pushing an image | package not linked to this repo (GHCR package access) |
| Spans missing in Arize, HTTP 200 on export | endpoint ends in `/v1` (path doubles) or project name not set |
| No email, red run | `RUN_PAID_MATCH` not `1`, SMTP secrets wrong, or the trends parquet unreachable |
