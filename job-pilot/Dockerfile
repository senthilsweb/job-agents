# job-pilot — build from the REPO ROOT (it needs job-scout's config for
# the owner's targets and board slugs):
#   docker build -f job-pilot/Dockerfile -t ghcr.io/senthilsweb/job-pilot .
# Pure-Python deps only (fpdf2, not WeasyPrint — Correction 1), so slim
# needs no apt packages.
FROM python:3.12-slim

WORKDIR /app/job-pilot

COPY job-scout/config.yaml /app/job-scout/config.yaml
COPY job-pilot/pyproject.toml ./
COPY job-pilot/pipeline ./pipeline
COPY job-pilot/templates ./templates
COPY job-pilot/inputs ./inputs
COPY job-pilot/config.yaml job-pilot/run.py ./

RUN pip install --no-cache-dir .

# Secrets and RUN_PAID_MATCH arrive as env vars at `docker run` time —
# nothing is baked into the image.
ENTRYPOINT ["python", "run.py"]
