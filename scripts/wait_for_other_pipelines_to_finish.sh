#!/bin/bash

if [[ -z "${CI_PROJECT_ID}" ]]; then
    echo -e "\033[0;31mERROR: Variable CI_PROJECT_ID is missing, are you using the script in gitlab ci pipeline?!\033[0m" >&2
    exit 1
fi
if [[ -z "${CI_PIPELINE_ID}" ]]; then
    echo -e "\033[0;31mERROR: Variable CI_PIPELINE_ID is missing, are you using the script in gitlab ci pipeline?!\033[0m" >&2
    exit 1
fi
if [[ -z "${CI_SERVER_URL}" ]]; then
    echo -e "\033[0;31mERROR: Variable CI_SERVER_URL is missing, are you using the script in gitlab ci pipeline?!\033[0m" >&2
    exit 1
fi
if [[ -z "${SECRET_GITLAB_ACCESS_TOKEN}" ]]; then
    echo -e "\033[0;31mERROR: Variable SECRET_GITLAB_ACCESS_TOKEN is missing, set it up to allow runner fetch data from gitlab ci api\033[0m" >&2
    exit 1
fi

printf 'Waiting...'
SHA=$(curl -sS --header "PRIVATE-TOKEN: $SECRET_GITLAB_ACCESS_TOKEN" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}" | jq -r .sha)
while [[ $(curl -sS --header "PRIVATE-TOKEN: $SECRET_GITLAB_ACCESS_TOKEN" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/pipelines" | jq -r "map(select(.sha == \"$SHA\"))" | grep running | wc -l) -gt 1 ]]; do
    printf '.'
    sleep 10
done

curl -sS --header "PRIVATE-TOKEN: $SECRET_GITLAB_ACCESS_TOKEN" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/pipelines" | jq -r "map(select(.sha == \"$SHA\"))"
if curl -sS --header "PRIVATE-TOKEN: $SECRET_GITLAB_ACCESS_TOKEN" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/pipelines" | jq -r "map(select(.sha == \"$SHA\"))" | grep "failed"; then
    echo -e "\033[0;31mERROR: Other pipeline in this merge request group already failed, check their status!\033[0m" >&2
    exit 1
fi