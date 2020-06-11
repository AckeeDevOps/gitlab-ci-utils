#!/bin/bash

# This script is a workaround to prevent issues with detached pipelines,
# see https://gitlab.com/gitlab-org/gitlab/-/issues/217340 and https://gitlab.com/gitlab-org/gitlab/-/issues/2950

set -eu -o pipefail

fail() {
  echo -e "\033[0;31mERROR: $1\033[0m" >&2
  exit 1
}

# Get non-detached pipelines for the current commit
get_pipelines() {
  local result=$(curl -sS -w '\nhttp_code=%{http_code}\n' -H "Private-Token: $SECRET_GITLAB_ACCESS_TOKEN" \
      "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/pipelines?sha=${CI_COMMIT_SHA}")
  local http_code=$(grep '^http_code=' <<< "$result" | cut -d= -f2)
  local response=$(grep -v '^http_code=' <<< "$result")
  if [ $http_code -gt 200 ]; then
    fail "Could not get pipelines from GitLab API. HTTP status code: $http_code. Response: $response"
  fi
  jq -r 'map(select(.ref | startswith("refs/merge-requests") | not))' <<< "$response"
}

pipelines_active() {
  get_pipelines | jq -e 'map(select(.status == "running" or .status == "pending" or .status == "created")) | length > 0' > /dev/null
}

pipelines_failed() {
  local pipelines=$(get_pipelines)
  if ! jq -e 'map(select(.status == "failed" or .status == "canceled")) | length > 0' <<< "$pipelines" > /dev/null; then
    # there is no failed pipeline
    return 1
  fi
  local latest_pipeline=$(jq -r '. | first' <<< "$pipelines")
  if jq -e 'select(.status != "success")' <<< "$latest_pipeline" > /dev/null; then
    # the latest pipeline was not successful
    return 0
  fi
  # we consider the pipeline group to be successful when the latest pipeline is successful
  # and all previous failed/canceled pipelines have updated_at and created_at < than created_at
  # from the latest pipeline
  jq -e --arg d "$(jq -r '.updated_at' <<< "$latest_pipeline")" \
      '.[1:] | map(select(.status == "failed" or .status == "canceled")) | map(select(.updated_at >= $d or .created_at >= $d)) | length > 0' <<< "$pipelines" > /dev/null
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
while pipelines_active; do
    printf '.'
    sleep 10
done
echo

get_pipelines

if pipelines_failed; then
    fail "Other pipeline in this merge request group already failed, check their status!"
fi
