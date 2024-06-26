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
  --driver docker-container \
  --driver-opt image=git.hd.caiweiqiang.cn:5001/docker-images/cache/moby/buildkit \
  --use \
  --bootstrap

docker_image_tag="${DRONE_BRANCH:-}"

if [[ "$docker_image_tag" = "master" || "$docker_image_tag" = "main" ]]; then
  docker_image_tag="latest"
fi

if [[ "${DRONE_TAG:-}" != "" ]]; then
  docker_image_tag="$DRONE_TAG"
fi

docker_build_cmd="docker buildx build --pull=true"

docker_build_cmd="$docker_build_cmd --label org.opencontainers.image.created=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
docker_build_cmd="$docker_build_cmd --label org.opencontainers.image.revision=${DRONE_COMMIT}"
docker_build_cmd="$docker_build_cmd --label org.opencontainers.image.source=${DRONE_GIT_HTTP_URL}"
docker_build_cmd="$docker_build_cmd --label org.opencontainers.image.url=${DRONE_REPO_LINK}"

if [[ "${PLUGIN_PLATFORM:-}" != "" ]]; then
  docker_build_cmd="$docker_build_cmd --platform $PLUGIN_PLATFORM"
fi

docker_build_cmd="$docker_build_cmd -t $PLUGIN_REPO:$docker_image_tag"

if [[ "${PLUGIN_CACHE:-none}" = "s3" ]]; then
  docker_build_cmd="$docker_build_cmd --cache-to   type=s3,region=${PLUGIN_CACHE_S3_REGION:-us-east-1},bucket=${PLUGIN_CACHE_S3_BUCKET},use_path_style=true,blobs_prefix=${DRONE_REPO}/blobs/,manifests_prefix=${DRONE_REPO}/manifests/,endpoint_url=${PLUGIN_CACHE_S3_ENDPOINT},access_key_id=${PLUGIN_CACHE_S3_ACCESS_KEY},secret_access_key=${PLUGIN_CACHE_S3_SECRET_KEY},name=docker-build-cache,mode=${PLUGIN_CACHE_MODE:-min},ignore-error=${PLUGIN_CACHE_IGNORE_ERROR:-false}"
  docker_build_cmd="$docker_build_cmd --cache-from type=s3,region=${PLUGIN_CACHE_S3_REGION:-us-east-1},bucket=${PLUGIN_CACHE_S3_BUCKET},use_path_style=true,blobs_prefix=${DRONE_REPO}/blobs/,manifests_prefix=${DRONE_REPO}/manifests/,endpoint_url=${PLUGIN_CACHE_S3_ENDPOINT},access_key_id=${PLUGIN_CACHE_S3_ACCESS_KEY},secret_access_key=${PLUGIN_CACHE_S3_SECRET_KEY},name=docker-build-cache"
fi

docker_build_cmd="$docker_build_cmd --push ."

$docker_build_cmd
