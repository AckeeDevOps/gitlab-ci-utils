FROM docker:stable

MAINTAINER Martin Beranek (martin.beranek112@gmail.com)

LABEL tag="ackee-gitlab" \
      author="Ackee 🦄" \
      description="An image containing a few scripts mainly focused on GitLab API calls"

COPY scripts/wait_for_other_pipelines_to_finish.sh /usr/local/bin/wait_for_other_pipelines_to_finish.sh
COPY scripts/wait_for_runtime.sh /usr/local/bin/wait_for_runtime.sh
COPY scripts/cf_add_record.sh /usr/local/bin/cf_add_record.sh
COPY scripts/cf_purge_by_url.sh /usr/local/bin/cf_purge_by_url.sh
COPY scripts/helper_functions.sh /usr/local/bin/helper_functions.sh

RUN wget -q https://releases.hashicorp.com/vault/1.5.4/vault_1.5.4_linux_amd64.zip -O vault.zip && \
    unzip vault.zip && \
    mv vault /usr/local/bin/vault && \
    chmod +x /usr/local/bin/vault && \
    rm vault.zip

RUN apk update \
    && apk upgrade \
    && apk add --no-cache bash jq curl openssh python3 py3-pip \
    && pip3 install yq \
    && chmod +x /usr/local/bin/wait_for_other_pipelines_to_finish.sh \
    && chmod +x /usr/local/bin/wait_for_runtime.sh \
    && chmod +x /usr/local/bin/cf_purge_by_url.sh \
    && chmod +x /usr/local/bin/cf_add_record.sh
