#!/usr/bin/env bash
# Waits until a URL answers with the expected release tag, so the health gate tests the new
# build and not the old container Azure keeps running while it pulls the new image.
#
# Usage: scripts/wait-for-version.sh <URL> <TAG> [TIMEOUT_SECONDS]
# Example: scripts/wait-for-version.sh https://app-quicktill-ioprww-staging.azurewebsites.net/version abc1234

set -euo pipefail

URL="${1:?Usage: $0 <URL> <TAG> [TIMEOUT_SECONDS]}"
TAG="${2:?Usage: $0 <URL> <TAG> [TIMEOUT_SECONDS]}"
TIMEOUT="${3:-600}"
deadline=$((SECONDS + TIMEOUT))

while [ "$SECONDS" -lt "$deadline" ]; do
  body=$(curl -fsS --max-time 5 "$URL" 2>/dev/null || true)
  if grep -qF "$TAG" <<<"$body"; then
    echo "$URL is running $TAG"
    exit 0
  fi
  echo "Waiting for $TAG at $URL (now: ${body:0:80})"
  sleep 15
done

echo "$URL did not start $TAG within ${TIMEOUT}s"
exit 1
