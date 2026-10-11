# job-agents

Three small, spec-driven agents that find, score and report on job postings.
One repo, three projects, **six deployable images**.

Docs: **https://www.senthilsweb.com/job-agents/**

```
job-scout ──parquet + trends/YYYYMMDD tag──► job-pilot ──/upload, /analyze──► job-matcher
                                                │  └─ Jev gate (location, role fit, resume variant)
                                                └──► digest email
```

## Projects

| Project | Role | What it does |
|---|---|---|
| [`job-scout`](job-scout/) | collect | Watches ~95 company job boards and publishes a daily public parquet of open postings plus a trends dashboard |
| [`job-matcher`](job-matcher/) | score | Resume vs posting: evidence-grounded, deterministic 40/20/20/20 scoring. REST API, CLI, MCP agent service, web GUIs |
| [`job-pilot`](job-pilot/) | orchestrate | Finds new jobs daily, gates them with TypeSafe Jev, scores via job-matcher, emails one digest with cover letters and the right resume |

## The six images

| # | GHCR image (frozen) | Source | One line | Runs as | Port |
|---|---|---|---|---|---|
| 1 | `job-scout` | `job-scout/` | Scrapes ATS boards, writes the daily parquet and trends | batch job (GitHub Actions) | n/a |
| 2 | `job-pilot` | `job-pilot/` | LangGraph digest pipeline with the Jev gate | batch job (GitHub Actions) | n/a |
| 3 | `agent-job-matcher` | `job-matcher/backend` | FastAPI scoring service (`/upload`, `/analyze`, `/health`) and CLI | service (home lab) | 6010 |
| 4 | `agent-job-matcher-agent-service` | `job-matcher/mcp/agent-service` | Chat/MCP agent service (REST and SSE) on top of the API | service (home lab) | 6011 |
| 5 | `agent-job-matcher-playground` | `job-matcher/playground` | Next.js web GUI to try a resume against a job | service (home lab) | 6012 |
| 6 | `agent-job-matcher-openapi-docs` | `job-matcher/openapi-docs` | Next.js web GUI rendering the API reference | service (home lab) | 6013 |

Also in the repo, not images: the static
[DuckDB console](utils/duckdb-s3-console.html) (published at `/console/`) and the
trends dashboard (published at `/trends/`).

## Jev (TypeSafe) in one paragraph

job-pilot asks TypeSafe's Jev three typed questions per new job — *where is
it*, *is it one of my target roles*, *which resume variant fits* — using only
public job facts (title, department, type, location, work mode, comp summary;
never job text, resume or company). `JEV_MODE` is `off` (string rules only,
default), `shadow` (Jev runs and is logged, nothing changes) or `enforce`
(confident Jev answers decide; low confidence falls back to the old rules; any
error falls back to the old rules and flags the digest). Details:
[job-pilot/docs/jev.md](job-pilot/docs/jev.md).

## Operating it

| Need | Where |
|---|---|
| How the pieces fit | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| Deploy, secrets, cutover, rollback | [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) |
| Daily digest and health check | [job-pilot/docs/runbook.md](job-pilot/docs/runbook.md) |
| Matcher API and stack | [job-matcher/docs/runbook.md](job-matcher/docs/runbook.md) |

Health check: `job-pilot health check` runs every 4 hours and emails an alert
when the home-lab API/agent, trace collectors, Jev or the trends data are down.
It makes only free probes, never an OpenAI or paid call.

## Naming

- Projects use `job-<role>` for directories, workflow files and docs paths.
- **Image names are frozen**: the home-lab deployment pulls
  `ghcr.io/senthilsweb/agent-job-matcher*`, so the matcher images keep their
  historical `agent-` prefix. Do not rename them.
- Workflow files are prefixed by project: `job-scout-*`, `job-matcher-*`,
  `job-pilot-*`, plus `site.yml` (the single GitHub Pages deployer).

## Layout

```
job-scout/    collector, trends dashboard, daily parquet (data/)
job-matcher/  backend (FastAPI + CLI), mcp/agent-service, playground, openapi-docs
job-pilot/    LangGraph digest pipeline, Jev gate, resume variants
docs/         umbrella wiki (mkdocs monorepo plugin)
openspec/     cross-project specs; each project also has its own openspec/
.github/      workflows and the health-check scripts
utils/        duckdb-s3-console.html
```

## Working agreement

Every non-trivial change goes through `openspec/changes/<name>/` (proposal,
design, tasks, spec) before and during implementation. See `AGENTS.md`.
