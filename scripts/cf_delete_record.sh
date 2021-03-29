#!/bin/bash

if [[ -z "${DOMAIN_ZONE_ID}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_ZONE_ID is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

if [[ -z "${DOMAIN_RECORD_TYPE}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_RECORD_TYPE is missing, set it up in CI settings.\033[0m" >&2
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

if [[ -z "${DOMAIN_CONTENT}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_CONTENT is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

DNS_RECORD_ID=$(curl -X GET "https://api.cloudflare.com/client/v4/zones/${DOMAIN_ZONE_ID}/dns_records" \
     -H "X-Auth-Key: ${DOMAIN_KEY}" \
     -H "X-Auth-Email: ${DOMAIN_EMAIL}" \
     -H "Content-Type: application/json" | \
     jq -r ".result | map(select(.zone_id == \"${DOMAIN_ZONE_ID}\")) | map(select(.type == \"${DOMAIN_RECORD_TYPE}\")) | map(select(.content == \"${DOMAIN_CONTENT}\")) | .[].id")

if [[ -z "${DNS_RECORD_ID}" ]]; then
    echo -e "\033[0;31mWARNING: Deleting a CloudFlare DNS record ${DOMAIN_CONTENT} skipped, record doesn't exists\033[0m" >&2
    exit 1
else
    curl -X DELETE "https://api.cloudflare.com/client/v4/zones/${DOMAIN_ZONE_ID}/dns_records/${DNS_RECORD_ID}" \
        -H "X-Auth-Key: ${DOMAIN_KEY}" \
        -H "X-Auth-Email: ${DOMAIN_EMAIL}" \
        -H "Content-Type:application/json"
fi

