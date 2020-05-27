#!/bin/bash

if [[ -z "${DOMAIN_ZONE_ID}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_ZONE_ID is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

if [[ -z "${DOMAIN_KEY}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_KEY is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

if [[ -z "${DOMAIN_EMAIL}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_EMAIL is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

if [[ -z "${PURGE_URL}" ]]; then
    echo -e "\033[0;31mERROR: Variable PURGE_URL is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

curl -X POST "https://api.cloudflare.com/client/v4/zones/${DOMAIN_ZONE_ID}/purge_cache" \
     -H "Content-Type:application/json" \
     -H "X-Auth-Key: ${DOMAIN_KEY}" \
     -H "X-Auth-Email: ${DOMAIN_EMAIL}" \
     --data "{\"files\":$(echo "$PURGE_URL" | grep '.' | jq  --raw-input . | jq -c --slurp .)}"
