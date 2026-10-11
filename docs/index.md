# job-agents

Three small, spec-driven agents that find, score and report on job postings.

| Project | Role | Image(s) on GHCR |
|---|---|---|
| **[job-scout](job-scout/index.md)** | Collect: watches ~95 company job boards and publishes a daily public parquet | `job-scout` |
| **[job-matcher](job-matcher/index.md)** | Score: resume vs posting, evidence-grounded, deterministic scoring | `agent-job-matcher`, `agent-job-matcher-agent-service`, `agent-job-matcher-playground`, `agent-job-matcher-openapi-docs` |
| **[job-pilot](job-pilot/index.md)** | Orchestrate: finds new jobs, gates them (Jev), scores via job-matcher, emails one digest | `job-pilot` |

The `agent-` prefix on the matcher images is historical. Image names are
frozen because the home-lab deployment pulls them.

## Live pages

- [Trends dashboard](https://www.senthilsweb.com/job-agents/trends/): daily hiring trends from the public dataset.
- [DuckDB console](https://www.senthilsweb.com/job-agents/console/): query the public parquet in your browser.

## How these are built

Every non-trivial change goes through a written proposal, design, tasks and
specs (`openspec/`) with an approval gate between phases. See the
[Documentation Style Guide](job-scout/style-guide.md).
