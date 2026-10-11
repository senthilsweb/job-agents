# job-agents

Three related, independently deployable projects. Read the project's own
`AGENTS.md`/`README.md` before changing it.

| Dir | Stack | Entry points |
|---|---|---|
| `job-scout/` | Python, DuckDB | `tools/`, `config.yaml` (target roles, board slugs), `data/ats_raw_trends.parquet` |
| `job-matcher/` | Python (FastAPI), Node (playground, openapi-docs, mcp) | `backend/job_matcher`, `mcp/agent-service`, `Dockerfile` |
| `job-pilot/` | Python, LangGraph | `run.py`, `pipeline/`, `config.yaml`, `inputs/resumes/` |

## Conventions

- **Do not rename GHCR images.** `job-scout`, `job-pilot` and the four
  `agent-job-matcher*` images are pulled by the home-lab deployment (a private
  repo) and by `job-pilot.yml`. A rename breaks them silently.
- **Contracts between projects:** job-pilot reads job-scout's committed
  parquet over HTTPS (`raw.githubusercontent.com/.../job-scout/data/...`, plus
  `trends/YYYYMMDD` tags) and calls job-matcher's `/upload` and `/analyze`.
  job-pilot also reads `job-scout/config.yaml` for target roles. Nothing else
  crosses project directories.
- **One Pages deploy per repo.** Only `.github/workflows/site.yml` calls
  `deploy-pages`. Add new docs to the mkdocs monorepo, never a second deployer.
- **Public repo.** Resumes are committed with the phone number replaced by
  `{{PHONE}}` (`job-pilot/tools/sync_resumes.py`); the real number comes from
  the `LETTERHEAD_PHONE` secret. Never commit raw resumes, `.env` files, or
  job-description text.
- Conventional commits; `fix(job-pilot):`, `feat(job-matcher):` scopes are the
  project names. Releases of job-matcher are tagged `job-matcher-v<X.Y.Z>`.
- Every non-trivial change goes through `openspec/changes/<name>/`.

## Secrets (GitHub Actions)

`JOBMATCH_API_BASE`, `JOBMATCH_AGENT_BASE`, `SMTP_HOST/PORT/USER/PASS`,
`DIGEST_TO`, `DIGEST_FROM`, `LETTERHEAD_PHONE`, `LANGSMITH_API_KEY`,
`OTEL_EXPORTER_OTLP_ENDPOINT/HEADERS`, `PHOENIX_COLLECTOR_ENDPOINT`,
`PHOENIX_CLIENT_HEADERS`, `TYPESAFE_API_KEY`. Variable: `JEV_MODE`.

## Where to read next

- `docs/ARCHITECTURE.md` (system view, the six images, where Jev sits)
- `docs/DEPLOYMENT.md` (images, secrets, GHCR access, home lab, rollback)
- `job-pilot/docs/jev.md` (the Jev gate)
