# Runbook

At the end you will know what runs by itself, how to check it, and what
to do when something fails.

## What runs automatically

| When | What | Output |
|---|---|---|
| Daily, after the 11:00 UTC trends publish | `job-pilot daily digest` workflow | one email to `DIGEST_TO` |
| Every push touching `job-pilot/` | `job-pilot tests and image` workflow | pytest + GHCR image on main |
| Every 4 hours at :17 | `job-pilot health check` workflow | an alert email only when something is down |

## The one daily check

**Did the email arrive?** A quiet day still sends a short "no new
matching jobs" email, and a `max_jobs_per_run` overflow still sends the
digest too — with the overflow called out in the Failures box, matching
skipped for that run only. **No email at all means the pipeline is
broken** (e.g. `RUN_PAID_MATCH` off, or a run-level failure like the
parquet or SMTP being unreachable) — open the repo's Actions tab and
look at the latest "job-pilot daily digest" run.

## Procedures with cost

- **Manual run**: Actions → "job-pilot daily digest" → Run workflow.
  Optional inputs: a baseline tag like `trends/20260710` to widen the
  window, and `max_jobs_per_run` to raise the per-run cap for one
  catch-up run (e.g. after several days skipped matching). Guard: never
  a paid call above the cap in effect, so the worst-case bill is
  bounded either way.
- **Local paid run**: set `RUN_PAID_MATCH=1` in `.env`, then
  `python run.py --dry-run --baseline trends/YYYYMMDD`. Same guard.

## Health check

Free probes only (never an OpenAI or paid call): job-matcher API and
agent `/health`, the Phoenix and OTLP trace collectors (an authenticated
empty POST), TypeSafe Jev reachability, and the trends parquet. Any
failure sends one formatted email and turns the run red. Dispatch it with
`force_email=true` to test SMTP and formatting, and `trace_probe=true` to
send one real span and print the collector's answer.

**A green digest with no matches is not proof of health.** If the home-lab
API is behind a tunnel that returns 502, jobs fail individually and the
run can still finish. The health-check email is the signal for that.

## Failures seen so far

| Symptom | Cause | Fix |
|---|---|---|
| Digest lists a job under "Failures" with "JD too short" | the job board serves a JavaScript shell; the ATS API had no text either | nothing to fix — the job is reported, not scored; apply manually if interesting |
| Digest lists a `match_cap` Failure ("N candidates exceed max_jobs_per_run") | wrong/old baseline, or a genuine coverage-expansion burst, made too many jobs look new in one run; matching was skipped, cost was zero | nothing to fix by default — the baseline advances and normal-sized deltas resume tomorrow; dispatch manually with a raised `max_jobs_per_run` input first if you want that specific batch matched instead of skipped |
| Arize spans silently missing; exporter logs "Internal Server Error" | Arize requires a `model_id` resource attribute on every span | already fixed in `pipeline/telemetry.py` (2026-07-15) — keep `model_id` if you touch tracing |
| Digest lists a `resumes` Failure ("expected exactly one sk-resume-…") | `inputs/resumes/` is missing a variant or holds two files for one | rerun `python tools/sync_resumes.py <dir>`; it leaves exactly one file per variant |
| Digest shows a `jev` Failure | Jev unreachable, key invalid or breaker open; rules decided instead | nothing to fix for that run; check the key and the health-check email. `JEV_MODE=off` removes the gate |
| `RUN_PAID_MATCH != 1 — refusing paid /analyze calls` (no email, workflow red) | the paid-call switch is off | set `RUN_PAID_MATCH=1` only when you intend to pay |

## Telemetry

Every run is one LangSmith trace (project `job-pilot`) and one OTel
trace fanned out to OpenObserve and Arize. Missing telemetry
configuration degrades to a logged warning — it never blocks the email.

Next: [CI/CD](ci-cd.md)
