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
