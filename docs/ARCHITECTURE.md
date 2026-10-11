# Architecture

The whole system on one page: what runs where, who calls whom, and what is
allowed to fail.

## System view

```mermaid
flowchart LR
    BOARDS[(Company job boards<br/>~95 ATS boards)] --> SCOUT

    subgraph GH[GitHub Actions - job-agents]
      SCOUT[job-scout<br/>daily trends 11:00 UTC]
      PILOT[job-pilot<br/>daily digest]
      HEALTH[health check<br/>every 4 h]
    end

    SCOUT -->|parquet on main +<br/>trends/YYYYMMDD tag| PILOT
    RESUME[(Resume variants<br/>phone-scrubbed in repo)] --> PILOT
    PILOT -->|3 typed questions<br/>public job facts only| JEV[TypeSafe Jev<br/>System One]
    PILOT -->|/upload + /analyze| API

    subgraph LAB[Home lab - docker compose]
      API[agent-job-matcher<br/>FastAPI :6010]
      AGENT[agent-service<br/>MCP + SSE :6011]
      PG[playground<br/>Next.js :6012]
      DOCS[openapi-docs<br/>Next.js :6013]
      AGENT --> API
      PG --> AGENT
    end

    API --> LLM[OpenAI]
    PILOT --> MAIL[Digest email<br/>cover letters + resume]
    PILOT -.->|OTLP| TRACES[Arize + OpenObserve]
    HEALTH -.->|GET /health| API
    HEALTH -.-> AGENT
    HEALTH -.-> JEV
    HEALTH -.-> TRACES
    HEALTH -.->|alert email| MAIL
```

## The six images

| Image | Project | One line |
|---|---|---|
| `job-scout` | job-scout | Scrapes ATS boards, writes the daily parquet and trends |
| `job-pilot` | job-pilot | LangGraph digest pipeline with the Jev gate |
| `agent-job-matcher` | job-matcher | FastAPI scoring service and CLI |
| `agent-job-matcher-agent-service` | job-matcher | Chat/MCP agent service over the API |
| `agent-job-matcher-playground` | job-matcher | Web GUI to try a match |
| `agent-job-matcher-openapi-docs` | job-matcher | Web GUI for the API reference |

## The daily pipeline (job-pilot)

```mermaid
flowchart LR
    A[parquet today] --> B[delta vs baseline tag<br/>DuckDB anti-join]
    B --> C[prefilter<br/>category + salary floor]
    C --> G{Jev gate<br/>JEV_MODE}
    G -->|off / low confidence / error| R[string rules<br/>fallback]
    G -->|enforce, confident| J[location, role fit,<br/>resume variant]
    R --> M[score via<br/>job-matcher]
    J --> M
    M --> P[cover-letter PDFs +<br/>chosen resume]
    P --> E[one digest email]
    C -. none .-> E
```

## Where Jev sits

| | Before Jev | With Jev (`enforce`) |
|---|---|---|
| Location | hand-kept list of states and cities; unknown strings dropped | Jev `choice`: `us`, `remote_us`, `non_us`, `unclear` |
| Role fit | substring match on titles | Jev `noul` score against target families (from job-scout `config.yaml`) |
| Resume variant | first matching title substring, else master | Jev `choice` among four variants |
| Rejections | a count | each reason recorded; near-misses flagged in the digest |
| On failure | n/a | confidence below threshold or any error falls back to the rules; circuit breaker after 5 errors |

What stays deterministic code: category set, salary floor, `RUN_PAID_MATCH`,
`max_jobs_per_run`. Jev replaces the fuzzy rules only.

## Contracts and boundaries

- **job-scout → job-pilot:** a committed parquet over HTTPS plus `trends/YYYYMMDD`
  tags as baselines. Nothing is imported across project directories except
  job-scout's `config.yaml` (target roles, board slugs, salary floor), which
  job-pilot reads so the targets stay single-sourced.
- **job-pilot → job-matcher:** `/upload` and `/analyze` over HTTPS. All LLM
  calls happen in job-matcher; job-pilot is deterministic code.
- **job-pilot → Jev:** `POST /v1/systemone`, whitelisted job facts only.
- **Privacy:** public repo, so no artifacts are uploaded by the digest, resumes
  are committed with `{{PHONE}}`, and logs carry counts and reasons only.

## Failure behaviour

| What breaks | Effect | Signal |
|---|---|---|
| Jev down or key missing | rules decide; digest flagged | digest Failures box |
| job-matcher down | matching fails per job, listed as failures | health-check email, digest |
| Trace collectors down | warning only; email still sends | health-check email |
| trends publish failed | digest does not run (it chains on success) | missing digest email |

## Schedule

| When (UTC) | What |
|---|---|
| 11:00 | job-scout daily trends, then triggers job-pilot digest on success |
| 11:45 | site (Pages) refresh, `/trends/` |
| every 4 h at :17 | job-pilot health check |
| on push | tests and image builds per project |
