# Gitlab CI Utils

This repo contains image for Gitlab CI pipelines with some basic scripts I found useful.

### wait_for_other_pipelines_to_finnish.sh

This is handy once you have detached pipelines in your merge request and you need to wait how other pipelines end up.

Usage example:

```yml
wait for all pipelines results:
  stage: wait
  image: beranm14/gitlab-ci-utils:latest
  script:
    - wait_for_other_pipelines_to_finnish.sh
```

### wait_for_runtime.sh

This script could be used once you have runner with concurrency larger than one and you need to wait for other pipelines
in the project to finnish. Script waits until other pipelines finnish and exit with zero to allow following job to
continue.

Usage example:

```yml
wait for all pipelines results:
  stage: wait
  image: beranm14/gitlab-ci-utils:latest
  script:
    - wait_for_runtime.sh
```
