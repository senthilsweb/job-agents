#!/usr/bin/env bash
# File Name: test-detect-changed-images.sh
# Description:
# Checks detect-changed-images.sh against throwaway git commits: each case
# touches one file and asserts which images would be built. Run it after
# editing the COMPONENTS table or the IGNORE/BUILD_ALL regexes.
#
# Usage: bash job-matcher/scripts/test-detect-changed-images.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/detect-changed-images.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
git init -q . && git config user.email t@t && git config user.name t
git commit -q --allow-empty -m base
BASE="$(git rev-parse HEAD)"

API=agent-job-matcher; AGENT=agent-job-matcher-agent-service
PLAY=agent-job-matcher-playground; DOCS=agent-job-matcher-openapi-docs
fail=0

# check <file> <expected images, space separated, or "none">
check() {
  local file="$1" want="$2" got
  git reset -q --hard "$BASE"
  mkdir -p "$(dirname "$file")"; echo "x$RANDOM" > "$file"
  git add -A && git commit -q -m t
  got="$( { bash "$SCRIPT" "$BASE..HEAD" | grep -o '"image":"[^"]*"' || true; } | sed 's/.*senthilsweb\///; s/"$//' | sort | tr '\n' ' ' | sed 's/ $//')"
  [ -z "$got" ] && got=none
  want="$(printf '%s\n' $want | sort | tr '\n' ' ' | sed 's/ $//')"
  if [ "$got" = "$want" ]; then echo "ok    $file -> $got"; else echo "FAIL  $file -> [$got] want [$want]"; fail=1; fi
}

check job-matcher/docs/architecture.md                  none
check job-matcher/docs/javascripts/tablesort.js         none
check job-matcher/openspec/changes/x/proposal.md        none
check job-matcher/README.md                             none
check job-matcher/AGENTS.md                             none
check job-matcher/backend/CHANGELOG.md                  none
check job-matcher/backend/tests/test_x.py               none
check job-matcher/backend/evals/rubrics.md              none
check job-matcher/mcp/README.md                         none
check job-matcher/mcp/test/x.test.js                    none
check job-matcher/playground/README.md                  none
check job-matcher/openapi-docs/README.md                none
check job-matcher/backend/job_matcher/pipeline.py       "$API $AGENT"
check job-matcher/backend/pyproject.toml                "$API $AGENT"
check job-matcher/Dockerfile                            "$API"
check job-matcher/mcp/index.js                          "$AGENT"
check job-matcher/mcp/package-lock.json                 "$AGENT"
check job-matcher/mcp/agent-service/app.py              "$AGENT"
check job-matcher/mcp/agent-service/Dockerfile          "$AGENT"
check job-matcher/playground/app/page.tsx               "$PLAY"
check job-matcher/openapi-docs/app/page.tsx             "$DOCS"
check .github/workflows/job-matcher-images.yml          "$API $AGENT $PLAY $DOCS"
check job-matcher/scripts/detect-changed-images.sh      "$API $AGENT $PLAY $DOCS"

# No resolvable range (tag push, manual run) builds everything.
n="$(bash "$SCRIPT" "" | grep -o '"image"' | wc -l | tr -d ' ')"
if [ "$n" = 4 ]; then echo "ok    empty range -> all 4"; else echo "FAIL  empty range -> $n images"; fail=1; fi

exit "$fail"
