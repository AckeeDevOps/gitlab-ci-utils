#!/bin/bash


if [[ -z "${DOMAIN_RECORD_TYPE}" ]]; then
    DOMAIN_RECORD_TYPE="CNAME"
fi

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

if [[ -z "${DOMAIN_CONTENT}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_CONTENT is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

if [[ -z "${DOMAIN_NAME}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_NAME is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

if [[ $(curl -X GET "https://api.cloudflare.com/client/v4/zones/53cfc44431c37e9d5d93db044c7a8bdb/dns_records" \
     -H "X-Auth-Key: ${DOMAIN_KEY}" \
     -H "X-Auth-Email: ${DOMAIN_EMAIL}" \
     -H "Content-Type: application/json" | \
     jq ".result | map(select(.zone_id == \"${DOMAIN_ZONE_ID}\")) | map(select(.type == \"${DOMAIN_RECORD_TYPE}\")) | map(select(.content == \"${DOMAIN_CONTENT}\"))") == "[]" ]]; then

    curl -X POST "https://api.cloudflare.com/client/v4/zones/${DOMAIN_ZONE_ID}/dns_records" \
        -H "Content-Type:application/json" \
        -H "X-Auth-Key: ${DOMAIN_KEY}" \
        -H "X-Auth-Email: ${DOMAIN_EMAIL}" \
        --data "{\"type\":\"${DOMAIN_RECORD_TYPE}\",\"name\":\"${DOMAIN_NAME}\",\"content\":\"${DOMAIN_CONTENT}\",\"ttl\":1,\"proxied\":true}" 2>/dev/null \
        | jq .success \
        | grep true \
    || echo -e "\033[0;31mERROR: Creating a CloudFlare DNS type ${DOMAIN_RECORD_TYPE} record ${DOMAIN_NAME} failed\033[0m" >&2

else
    echo -e "\033[0;31mWARNING: Creating a CloudFlare DNS type ${DOMAIN_RECORD_TYPE} record skipped, record already in place\033[0m" >&2
fi

