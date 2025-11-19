#!/usr/bin/env bash
set -euo pipefail
# generate-matrix.sh
# Produces a JSON matrix with top-level changed folders (excludes .github and docs)

# Use hard-coded default branch 'main' per user request
DEFAULT_BRANCH="main"

if [ -z "${GITHUB_SHA:-}" ]; then
  echo "GITHUB_SHA not set; are you running inside GitHub Actions?" >&2
  exit 1
fi

if [ -n "${TEST_DIFF:-}" ]; then
  DIFF="$TEST_DIFF"
else
  # For new branch pushes github.event.created is true; prefer that over checking for all-zero before SHA
  if [ "${GITHUB_EVENT_CREATED:-}" = "true" ] || [ -z "${GITHUB_EVENT_BEFORE:-}" ]; then
    echo "in IF/THEN block"
    echo "--GITHUB_EVENT_CREATED--"
    echo "${GITHUB_EVENT_CREATED:-}"
    echo ""
    echo "--GITHUB_EVENT_BEFORE--"
    echo "${GITHUB_EVENT_BEFORE:-}"
    echo ""
    git fetch origin "$DEFAULT_BRANCH" --depth=1
    BASE_SHA=$( git rev-parse origin/$DEFAULT_BRANCH )
  else
    echo "in IF/ELSE block"
    echo "--GITHUB_EVENT_BEFORE--"
    echo "${GITHUB_EVENT_BEFORE:-}"
    echo ""
    git fetch origin "$GITHUB_EVENT_BEFORE" --depth=1 || true
    BASE_SHA="$GITHUB_EVENT_BEFORE"
  fi
  echo "--BASE_SHA--"
  echo "$BASE_SHA"
  echo ""

  # Collect changed files/folders, filter out .github and docs
  DIFF=$( git diff --dirstat=files,0,cumulative "$BASE_SHA" "$GITHUB_SHA" | awk -F ' ' '{print $2}' | grep -vE '(^.github)' || true )
  echo "--DIFF--"
  echo "$DIFF"
  echo ""
fi

# Extract top-level directories only (ignore files in repo root) and dedupe
TOP_LEVEL=$( printf "%s\n" "$DIFF" | grep '/' | awk -F/ '{print $1}' | grep -vE '^(\\.github)$' | sort -u || true )
echo "--TOP_LEVEL--"
echo "$TOP_LEVEL"
echo ""

# Build JSON
JSON='{"paths":['
first=true
while IFS= read -r p; do
  [ -z "$p" ] && continue
  if [ "$first" = true ]; then
    JSON="$JSON\"$p\""
    first=false
  else
    JSON="$JSON,\"$p\""
  fi
done <<< "$TOP_LEVEL"
JSON="$JSON]}"

# Export matrix via GITHUB_OUTPUT if available (GitHub Actions); otherwise skip
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "matrix<<EOF" >> "$GITHUB_OUTPUT"
  echo "$JSON" >> "$GITHUB_OUTPUT"
  echo "EOF" >> "$GITHUB_OUTPUT"
fi

# Also print to logs for debugging
echo "$JSON"
