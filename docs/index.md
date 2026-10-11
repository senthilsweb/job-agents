# job-agents

Three small, spec-driven agents that find, score and report on job postings.
One repo, three projects, six deployable images.

| Project | Role | What it does |
|---|---|---|
| **[job-scout](job-scout/index.md)** | Collect | Watches ~95 company job boards and publishes a daily public parquet and trends |
| **[job-matcher](job-matcher/index.md)** | Score | Resume vs posting: evidence-grounded, deterministic scoring; REST API, CLI, MCP agent, web GUIs |
| **[job-pilot](job-pilot/index.md)** | Orchestrate | Finds new jobs, gates them with Jev, scores via job-matcher, emails one digest |

## The six images

| Image | One line | Runs as |
|---|---|---|
| `job-scout` | Scrapes ATS boards, writes the daily parquet and trends | batch job |
| `job-pilot` | LangGraph digest pipeline with the Jev gate | batch job |
| `agent-job-matcher` | FastAPI scoring service and CLI (port 6010) | service |
| `agent-job-matcher-agent-service` | Chat/MCP agent service over the API (6011) | service |
| `agent-job-matcher-playground` | Web GUI to try a match (6012) | service |
| `agent-job-matcher-openapi-docs` | Web GUI for the API reference (6013) | service |

The `agent-` prefix on the matcher images is historical. Image names are
frozen because the home-lab deployment pulls them.

## Start here

- [Architecture](ARCHITECTURE.md): how the pieces fit, where Jev sits, what may fail.
- [Deployment](DEPLOYMENT.md): images, secrets, GHCR access, home lab, rollback.
- [Jev gate](job-pilot/jev.md): modes, questions, thresholds, privacy.

## Live pages

- [Trends dashboard](https://www.senthilsweb.com/job-agents/trends/): daily hiring trends from the public dataset.
- [DuckDB console](https://www.senthilsweb.com/job-agents/console/): query the public parquet in your browser.

## How these are built

Every non-trivial change goes through a written proposal, design, tasks and
specs (`openspec/`) with an approval gate between phases. See the
[Documentation Style Guide](job-scout/style-guide.md).
