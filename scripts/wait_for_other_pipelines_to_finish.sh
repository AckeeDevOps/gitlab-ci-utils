#!/bin/bash

set -eu -o pipefail

fail() {
  echo -e "\033[0;31mERROR: $1\033[0m" >&2
  exit 1
}

get_pipelines() {
  curl -sS -H "Private-Token: $SECRET_GITLAB_ACCESS_TOKEN" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/pipelines?sha=${CI_COMMIT_SHA}" | \
      jq -r 'map(select(.ref | startswith("refs/merge-requests") | not))'
}

if [[ -z "${CI_PROJECT_ID-}" ]]; then
    fail "Variable CI_PROJECT_ID is missing, are you using the script in gitlab ci pipeline?!"
fi
if [[ -z "${CI_SERVER_URL-}" ]]; then
    fail "Variable CI_SERVER_URL is missing, are you using the script in gitlab ci pipeline?!"
fi
if [[ -z "${CI_COMMIT_SHA-}" ]]; then
    fail "Variable CI_COMMIT_SHA is missing, are you using the script in gitlab ci pipeline?!"
fi
if [[ -z "${SECRET_GITLAB_ACCESS_TOKEN-}" ]]; then
    fail "Variable SECRET_GITLAB_ACCESS_TOKEN is missing, set it up to allow runner fetch data from gitlab ci api"
fi

printf 'Waiting...'
while [[ $(get_pipelines | grep running | wc -l) -gt 1 ]]; do
    printf '.'
    sleep 10
done
echo

pipelines=$(get_pipelines)
echo "$pipelines"
if grep -q "failed" <<< "$pipelines"; then
    fail "Other pipeline in this merge request group already failed, check their status!"
fi
