FROM docker:stable

MAINTAINER Martin Beranek (martin.beranek112@gmail.com)

RUN apk update
RUN apk upgrade
RUN apk add --no-cache curl python3 python3-dev py-pip build-base libffi-dev openssl-dev libgcc bash jq curl tini libcap openssl net-tools ca-certificates openssh ca-certificates git openssh curl

ENV KUBE_LATEST_VERSION="v1.17.3"
ENV HELM_VERSION="v3.1.0"

COPY scripts/wait_for_other_pipelines_to_finish.sh /usr/local/bin/wait_for_other_pipelines_to_finish.sh
COPY scripts/wait_for_other_pipelines_to_finish.sh /usr/local/bin/wait_for_other_pipelines_to_finnish.sh
COPY scripts/wait_for_runtime.sh /usr/local/bin/wait_for_runtime.sh
COPY scripts/cf_add_record.sh /usr/local/bin/cf_add_record.sh

RUN wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && chmod +x /usr/local/bin/wait_for_other_pipelines_to_finish.sh \
    && chmod +x /usr/local/bin/wait_for_other_pipelines_to_finnish.sh \
    && chmod +x /usr/local/bin/wait_for_runtime.sh \
    && chmod +x /usr/local/bin/cf_add_record.sh

