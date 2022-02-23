#!/bin/bash

if [[ -z "${DOMAIN_ZONE_ID}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_ZONE_ID is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

if [[ -z "${PURGE_URL}" ]]; then
    echo -e "\033[0;31mERROR: Variable PURGE_URL is missing, set it up in CI settings.\033[0m" >&2
    exit 1
fi

if [[ -z "${DOMAIN_KEY}" && -z "${DOMAIN_TOKEN}" ]]; then
    echo -e "\033[0;31mERROR: Variable DOMAIN_KEY and DOMAIN_TOKEN are missing, set one of it in CI settings.\033[0m" >&2
    exit 1
fi

if [[ -n "${DOMAIN_KEY}" ]]; then
  if [[ -z "${DOMAIN_EMAIL}" ]]; then
      echo -e "\033[0;31mERROR: Variable DOMAIN_EMAIL is missing, set it up in CI settings.\033[0m" >&2
      exit 1
  fi
  curl -X POST "https://api.cloudflare.com/client/v4/zones/${DOMAIN_ZONE_ID}/purge_cache" \
       -H "Content-Type:application/json" \
       -H "X-Auth-Key: ${DOMAIN_KEY}" \
       -H "X-Auth-Email: ${DOMAIN_EMAIL}" \
       --data "{\"files\":${PURGE_URL}}"
elif [[ -n "${DOMAIN_TOKEN}" ]]; then
  curl -X POST "https://api.cloudflare.com/client/v4/zones/${DOMAIN_ZONE_ID}/purge_cache" \
       -H "Authorization: Bearer ${DOMAIN_TOKEN}" \
       --data "{\"files\":${PURGE_URL}}"
fi
