# job-agents

Three small, spec-driven agents that find, score and report on job postings.

| Project | Role | What it does | GHCR image(s) |
|---|---|---|---|
| [`job-scout`](job-scout/) | collect | Watches ~95 company job boards, publishes a daily public parquet of open postings and a trends dashboard | `job-scout` |
| [`job-matcher`](job-matcher/) | score | Resume vs posting, evidence-grounded, deterministic scoring. REST API, CLI, MCP agent service | `agent-job-matcher`, `agent-job-matcher-agent-service`, `agent-job-matcher-playground`, `agent-job-matcher-openapi-docs` |
| [`job-pilot`](job-pilot/) | orchestrate | Finds new jobs, gates them (TypeSafe Jev), scores via job-matcher, emails one digest with cover letters | `job-pilot` |

Docs: **https://www.senthilsweb.com/job-agents/**

```
job-scout ──parquet + trends/YYYYMMDD tag──► job-pilot ──/upload, /analyze──► job-matcher
                                                │  └─ Jev gate (location, role fit, resume variant)
                                                └──► digest email
```

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
```

## Working agreement

Every non-trivial change goes through `openspec/changes/<name>/` (proposal,
design, tasks, spec) before and during implementation. See
`AI-SDLC-TAILORING.md`.
