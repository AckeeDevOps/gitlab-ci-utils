FROM docker:stable

MAINTAINER Martin Beranek (martin.beranek112@gmail.com)

COPY scripts/wait_for_other_pipelines_to_finish.sh /usr/local/bin/wait_for_other_pipelines_to_finish.sh
COPY scripts/wait_for_runtime.sh /usr/local/bin/wait_for_runtime.sh
COPY scripts/cf_add_record.sh /usr/local/bin/cf_add_record.sh
COPY scripts/cf_purge_by_url.sh /usr/local/bin/cf_purge_by_url.sh

RUN apk update \
    && apk upgrade \
    && apk add --no-cache build-base libffi-dev openssl-dev libgcc bash jq curl tini libcap openssl net-tools ca-certificates git openssh \
    && chmod +x /usr/local/bin/wait_for_other_pipelines_to_finish.sh \
    && chmod +x /usr/local/bin/wait_for_runtime.sh \
    && chmod +x /usr/local/bin/cf_purge_by_url.sh \
    && chmod +x /usr/local/bin/cf_add_record.sh
