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
while true; do
    READY=$(
        curl -sS --header "PRIVATE-TOKEN: $SECRET_GITLAB_ACCESS_TOKEN" \
        "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/pipelines?order_by=id&sort=asc&scope=running" \
        | jq '.[0].id=='"${CI_PIPELINE_ID}"
    )
    if [[ "${READY}" = "true" ]]; then
        printf '\nReady!'
        exit 0
    else
        printf '.'
        sleep 10
    fi
done
