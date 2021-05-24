error() {
  echo -e "\033[0;31mERROR: $1\033[0m" >&2
}

warn() {
  echo -e "\033[0;33mWARNING: $1\033[0m" >&2
}

info() {
  echo -e "\033[0;32mINFO: $1\033[0m" >&2
}

fail() {
  error "$1"
  exit 1
}

read_config() {
  local path="$CI_PROJECT_DIR/$1"
  if [ -s "$path" ]; then
    source "$path"
    if grep -q -v '^#' "$path"; then
      export $(grep -v '^#' "$path" | cut -d= -f1)
    fi
  else
    fail "Config $path does not exist or is empty"
  fi
}

check_empty_vars() {
  fail_flag=false
  for var in "$@"; do
    if [ -z "$(eval echo \$"$var")" ]; then
      error "Variable $var is not set."
      fail_flag=true
    fi
  done
  if [ "$fail_flag" = true ]; then
    exit 1
  fi
}

get_branch_config_path() {
  if [ -f "$CI_PROJECT_DIR/ci-branch-config/$CI_COMMIT_REF_NAME.env" ]; then
    echo ci-branch-config/"$CI_COMMIT_REF_NAME.env"
  else
    # Some projects use "release" branches in format `${ENVIRONMENT_NAME}-${SEMVER_TAG}`
    local environment_name=$(echo "$CI_COMMIT_REF_NAME" | sed -E 's/(.+)-[0-9x]+\.[0-9]+\.[0-9]+/\1/')
    if [ -f "$CI_PROJECT_DIR/ci-branch-config/$environment_name.env" ]; then
      echo ci-branch-config/"$environment_name.env"
    fi
  fi
}

is_potentially_dynamic_environment() {
  if [[ "$CI_COMMIT_BRANCH" =~ development.* ]]; then
      echo ci-branch-config/"$CI_COMMIT_BRANCH.env"
  fi
}

read_branch_config() {
  read_config ci-branch-config/common.env
  local branch_config_path=$(get_branch_config_path)
  if [ -n "$branch_config_path" ]; then
    read_config "$branch_config_path"
  fi
}

# we can't do this in `variables:`, because branch configuration
# is loaded after resolving `$GCP_PROJECT_ID` variable
get_image_name() {
  read_branch_config
  echo "$DOCKER_REGISTRY_URL/$GCP_PROJECT_ID/$CI_PROJECT_NAME"
}

# because it is not possible to use variables in `rules:exist`
# see also https://gitlab.com/gitlab-org/gitlab/issues/16733
skip_if_brach_config_missing_dynamic_env() {
  if [ -z "$(get_branch_config_path)" ]; then
    if [ -n "$(is_potentially_dynamic_environment)" ]; then
      info "There is no ci-branch-config/$CI_COMMIT_REF_NAME.env but branch can be potentially used for test environment deployment."
    else
      info "There is no ci-branch-config/$CI_COMMIT_REF_NAME.env for the current branch, job will be skipped."
      exit 0
    fi
  fi
}

skip_if_brach_config_missing() {
  if [ -z "$(get_branch_config_path)" ]; then
    info "There is no ci-branch-config/$CI_COMMIT_REF_NAME.env for the current branch, job will be skipped."
    exit 0
  fi
}

docker_login() {
  echo "$GCP_SA_KEY" | base64 -d > "$GCP_SA_KEY_JSON_PATH"
  docker login -u _json_key --password-stdin eu.gcr.io < "$GCP_SA_KEY_JSON_PATH"
}

# run Docker Compose CI override
docker_compose_ci() {
  local command=$@

  cd "$CI_PROJECT_DIR/docker-compose"
  DOCKER_IMAGE_NAME="$(get_image_name)" docker-compose -p "$DOCKER_COMPOSE_PROJECT_NAME" \
      -f docker-compose.yml -f docker-compose.ci.yml $command
  cd "$OLDPWD"
}

init_ssh_agent() {
  if [ -n "$SECRET_GITLAB_SSH_KEY" ]; then
    eval $(ssh-agent -s) && echo "$SECRET_GITLAB_SSH_KEY" | ssh-add - && \
    mkdir -p ~/.ssh && ssh-keyscan -t rsa gitlab.ack.ee >> ~/.ssh/known_hosts
  fi
}

commits_count() {
  curl -s --HEAD --header "PRIVATE-TOKEN: $SECRET_GITLAB_ACCESS_TOKEN" "${CI_SERVER_URL}/api/v4/projects/$CI_PROJECT_ID/repository/commits?per_page=1&ref_name=$CI_COMMIT_REF_NAME" | grep x-total: | cut -d " " -f2
}

generate_changelog() {
  # fetch all commits between current SHA and SHA-1 (previous commit on autodeploy branches should be merge commit so it returns list of changes since last merge == since last version)
  curl -s -H "PRIVATE-TOKEN: ${SECRET_GITLAB_ACCESS_TOKEN}" "${CI_SERVER_URL}/api/v4/projects/${CI_PROJECT_ID}/repository/compare?from=${CI_COMMIT_SHA}~1&to=${CI_COMMIT_SHA}" |
  grep -Eo '"title":".*?",' | # find all commit titles
  sed -n 's|.*"title":"\([^"]*\)".*|• \1|p' | # extract and format commit titles
  tail -n +2 # remove first title which is duplicate of the last one (see raw output of curl above)
}

gcm_write_log() {
  local log_name=$1
  local payload=$2

  gcloud logging write $log_name "$payload" --project=$GCP_PROJECT_ID --payload-type=json
}

gcm_write_metric() {
  # metric format documentation: https://cloud.google.com/monitoring/custom-metrics/creating-metrics#writing-ts
  local metric_type=$1
  local labels=$2
  local value=$3
  # https://cloud.google.com/monitoring/api/ref_v3/rest/v3/TypedValue
  local value_type=$4
  local metric_kind=${5:-GAUGE}

  curl -sS \
    -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json; charset=utf-8' \
    "https://monitoring.googleapis.com/v3/projects/${GCP_PROJECT_ID}/timeSeries" \
    -d "{
      \"timeSeries\": [
        {
          \"metric\": {
            \"type\":\"custom.googleapis.com/$metric_type\",
            \"labels\": $labels
          },
          \"resource\": {
            \"type\": \"global\",
            \"labels\": {
              \"project_id\":\"$GCP_PROJECT_ID\"
            }
          },
          \"metricKind\": \"$metric_kind\",
          \"points\": [
            {
              \"interval\": {
                \"endTime\":\"$(date -Iseconds)\"
              },
              \"value\": {
                \"$value_type\": $value
              }
            }
          ]
        }
      ]
    }"
}
