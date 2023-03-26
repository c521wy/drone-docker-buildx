#!/usr/bin/env sh

set -eux

/usr/local/bin/dockerd-entrypoint.sh &

sleep 30

unset DOCKER_HOST

docker info

docker login -u "$PLUGIN_USERNAME" -p "$PLUGIN_PASSWORD" "$PLUGIN_REGISTRY"

docker buildx create \
  --driver docker-container \
  --driver-opt image=git.hd.caiweiqiang.cn:5001/docker-images/cache/moby/buildkit \
  --use \
  --bootstrap


docker_image_tag="$DRONE_BRANCH"

if [[ "$DRONE_BRANCH" = "master" || "$DRONE_BRANCH" = "main" ]]; then
  docker_image_tag="latest"
fi

if [[ "$DRONE_TAG" != "" ]]; then
  docker_image_tag="$DRONE_TAG"
fi


docker_build_cmd="docker buildx build"

if [[ "$PLUGIN_PLATFORM" != "" ]]; then
  docker_build_cmd="$docker_build_cmd --platform $PLUGIN_PLATFORM"
fi

docker_build_cmd="$docker_build_cmd -t $PLUGIN_REPO:$docker_image_tag"

docker_build_cmd="$docker_build_cmd --push ."

$docker_build_cmd
