# job-pilot

One email a day about new jobs that fit you — with ready-to-send cover
letters attached.

Every morning, [job-scout](../job-scout/index.md) publishes a public
parquet snapshot of open jobs at ~95 technology companies. job-pilot
runs right after that publish. It finds the jobs that are **new since
its last run** and match your target roles, sends only those to the
deployed job-matcher API for scoring, renders cover-letter PDFs on your
personal letterhead for the good matches, and emails you one digest.

## The daily flow

```mermaid
flowchart LR
    A[public trends parquet] --> B[find new jobs<br/>DuckDB anti-join]
    B --> C[filter by your<br/>target roles]
    C --> J[Jev gate<br/>location, role, variant]
    J --> D[score via<br/>job-matcher API]
    D --> E[cover-letter PDFs<br/>on your letterhead]
    E --> F[one digest email]
    C -- no candidates --> F
```

A quiet day still sends a short email. Silence always means the
pipeline is broken, never that there was nothing.

## Four ideas the design stands on

- **Stateless.** There is no database. DuckDB (in memory) compares two
  public parquet URLs — today's file against the dated tag of the last
  successful run. Each job is analyzed exactly once by construction.
- **No LLM inside.** All model calls happen in the deployed job-matcher
  API. job-pilot itself is deterministic code, so its tests are plain
  pytest — 114 of them, no network, no secrets.
- **Bounded cost.** Paid calls need `RUN_PAID_MATCH=1` (its absence
  hard-aborts the run), and matching is skipped for the run — never
  aborted — if the day's delta exceeds `max_jobs_per_run` (25); the
  digest still sends and reports it.

- **Fuzzy decisions are delegated, with a fallback.** Location, role
  fit and resume variant are decided by TypeSafe's Jev when
  `JEV_MODE=enforce`; low confidence or any error falls back to the
  string rules. See [Jev gate](jev.md).

It is a LangGraph pipeline. The graph is not decoration: version 2 adds
human-in-the-loop approval for outreach messages, which plugs into
LangGraph's checkpointer without a rewrite (see
[ADR 0003](https://github.com/senthilsweb/job-agents/blob/main/openspec/adr/0003-langgraph-for-python-orchestration.md)).

Next: [Getting Started](getting-started.md)
