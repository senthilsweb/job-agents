# CHANGELOG


## v0.1.0 (2026-10-11)

### Continuous Integration

- Build only the images whose Dockerfile inputs changed
  ([`bd28e03`](https://github.com/senthilsweb/job-agents/commit/bd28e0342578f2041e51e8afdff00d812af4f1f5))

- job-pilot image: path filter limited to what the Dockerfile COPYs; a changes job skips the build
  for tests-only pushes - job-matcher images: per-image regexes match COPY lines (no tests, evals,
  changelog, mcp/test); detector ignores docs, specs, markdown - job-scout image: markdown excluded
  from the path filter - add test-detect-changed-images.sh (24 cases), run in CI before detect -
  DEPLOYMENT.md: input table per image and how to change it

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>

Claude-Session: https://claude.ai/code/session_01RHHmJczPYkn56WNNHWkDoN

### Documentation

- Readme, architecture, deployment guide and Jev gate page
  ([`d404394`](https://github.com/senthilsweb/job-agents/commit/d404394a92c15f6b599acf67568fa035577d0490))

- README: six-image table with one-liners and ports, Jev summary - ARCHITECTURE: system view, Jev
  gate, failure behaviour, schedule - DEPLOYMENT (new): images, secrets, GHCR access, baseline tags,
  home lab, rollback - job-pilot: jev.md (new), health check in runbook and ci-cd, JEV_MODE in
  config - fix stale ai-agents / ai-job-pilot references and the test count (114)

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>

Claude-Session: https://claude.ai/code/session_01RHHmJczPYkn56WNNHWkDoN

### Features

- Initial import of job-scout, job-matcher and job-pilot
  ([`4240209`](https://github.com/senthilsweb/job-agents/commit/42402093ac2a8da6a6bfd1233a6ca9690d4c6e39))

Consolidates the three related job projects into one public repo: - job-scout from
  senthilsweb/ai-agents agents/job-scout - job-pilot from senthilsweb/ai-agents agents/job-pilot -
  job-matcher from senthilsweb/agent-job-matcher

Naming: job-<role> for directories, workflow files and docs paths. GHCR image names are unchanged
  (job-scout, job-pilot, agent-job-matcher*) so the home-lab deployment keeps working. Matcher
  workflows are prefixed job-matcher-*; docs fold into one Pages deploy (site.yml).

Imported without history. Generated graph files are not carried over.

Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>

Claude-Session: https://claude.ai/code/session_01RHHmJczPYkn56WNNHWkDoN
