#!/usr/bin/env bash

set -eux

/usr/local/bin/dockerd &

unset DOCKER_HOST

for ((i = 0; ; ++i)); do
  if docker info 2>/dev/null; then
    break
  fi

  if ((i > 60)); then
    docker info
    exit 1
  fi

  sleep 1
done

docker login -u "$PLUGIN_USERNAME" -p "$PLUGIN_PASSWORD" "${PLUGIN_REGISTRY:-docker.io}"

docker buildx create \
  --name drone-buildx \
  --driver docker-container \
  --driver-opt image="${PLUGIN_BUILDKIT_IMAGE:-git.hd.caiweiqiang.cn:5001/docker-images/cache/moby/buildkit}" \
  --use \
  --bootstrap

if [[ -n "${PLUGIN_TAGS:-}" ]]; then
  IFS=',' read -r -a docker_image_tag <<< "${PLUGIN_TAGS}"
else
  docker_image_tag=()
  [[ -n "${DRONE_BRANCH:-}" ]] && docker_image_tag+=("${DRONE_BRANCH}")
  [[ "${DRONE_BRANCH:-}" = "master" || "${DRONE_BRANCH:-}" = "main" ]] && docker_image_tag+=("latest")
  [[ -n "${DRONE_TAG:-}" ]] && docker_image_tag+=("${DRONE_TAG}")
fi

docker_build_cmd="docker buildx build --pull=true"

docker_build_cmd="$docker_build_cmd --label org.opencontainers.image.created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
docker_build_cmd="$docker_build_cmd --label org.opencontainers.image.revision=${DRONE_COMMIT}"
docker_build_cmd="$docker_build_cmd --label org.opencontainers.image.source=${DRONE_GIT_HTTP_URL}"
docker_build_cmd="$docker_build_cmd --label org.opencontainers.image.url=${DRONE_REPO_LINK}"

if [[ "${PLUGIN_PLATFORM:-}" != "" ]]; then
  docker_build_cmd="$docker_build_cmd --platform $PLUGIN_PLATFORM"
fi

docker_image_repo="${PLUGIN_REPO:-${PLUGIN_REGISTRY:-}/${DRONE_REPO}}"

for tag in "${docker_image_tag[@]}"; do
  docker_build_cmd="$docker_build_cmd -t $docker_image_repo:$tag"
done

if [[ "${PLUGIN_CACHE:-none}" = "s3" ]]; then
  prefix=${PLUGIN_CACHE_S3_PREFIX:-${DRONE_REPO}/docker-build-cache}

  name=()
  [[ -n "${DRONE_BRANCH:-}" ]] && name+=("git-branch:${DRONE_BRANCH}")
  name+=("git-commit:${DRONE_COMMIT}")

  docker_build_cmd="$docker_build_cmd --cache-to     type=s3,region=${PLUGIN_CACHE_S3_REGION:-us-east-1},bucket=${PLUGIN_CACHE_S3_BUCKET},use_path_style=true,endpoint_url=${PLUGIN_CACHE_S3_ENDPOINT},access_key_id=${PLUGIN_CACHE_S3_ACCESS_KEY},secret_access_key=${PLUGIN_CACHE_S3_SECRET_KEY},prefix=${prefix},name=$(IFS=';'; echo "${name[*]}"),mode=${PLUGIN_CACHE_MODE:-min},ignore-error=${PLUGIN_CACHE_IGNORE_ERROR:-false}"
  for _name in "${name[@]}"; do
    docker_build_cmd="$docker_build_cmd --cache-from type=s3,region=${PLUGIN_CACHE_S3_REGION:-us-east-1},bucket=${PLUGIN_CACHE_S3_BUCKET},use_path_style=true,endpoint_url=${PLUGIN_CACHE_S3_ENDPOINT},access_key_id=${PLUGIN_CACHE_S3_ACCESS_KEY},secret_access_key=${PLUGIN_CACHE_S3_SECRET_KEY},prefix=${prefix},name=${_name}"
  done
fi

docker_build_cmd="$docker_build_cmd --push ."

$docker_build_cmd
