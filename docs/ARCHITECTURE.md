# Architecture

```mermaid
flowchart LR
    BOARDS[(Company job boards)] --> SCOUT[job-scout<br/>daily trends parquet]
    SCOUT -->|trends/YYYYMMDD tag| PILOT[job-pilot<br/>daily digest]
    RESUME[(Resume variants<br/>private repo, synced)] --> PILOT
    PILOT -->|ask: location, role, variant| JEV[TypeSafe Jev]
    PILOT -->|/upload + /analyze| MATCHER[job-matcher<br/>home lab]
    MATCHER --> LLM[OpenAI]
    PILOT --> MAIL[Digest email<br/>+ cover letters + resume]
    HEALTH[health check<br/>every 4 h] -.->|GET /health| MATCHER
    HEALTH -.-> JEV
    PILOT -.->|OTLP| TRACES[Arize / OpenObserve]
```

- **Schedule:** job-scout's trends workflow runs at 11:08 UTC and triggers the
  job-pilot digest on success.
- **Contract between projects:** job-pilot reads job-scout's committed parquet
  over HTTPS and calls job-matcher's `/upload` and `/analyze`. Nothing is
  imported across project directories except job-scout's `config.yaml`
  (target roles, board slugs), which job-pilot reads so the targets stay
  single-sourced.
- **Deployment:** the six GHCR images are built by this repo's workflows.
  The home lab pulls the four `agent-job-matcher*` images.
