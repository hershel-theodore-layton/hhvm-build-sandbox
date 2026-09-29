#!/usr/bin/env bash
# Keep the container after failure so compilers/dependencies can be reused.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
container=${CONTAINER:-hhvm-arm64-build}
jobs=${JOBS:-$(docker info --format '{{.NCPU}}')}
memory=${BUILD_MEMORY:-15g}
swap=${BUILD_MEMORY_SWAP:-16g}
tag=${IMAGE_TAG:-26.09.29-arm64}
mkdir -p logs out/arm64
log="logs/build-arm64-$(date +%Y%m%d-%H%M%S).log"
echo "Build output: $PWD/$log (read after the command finishes)"
trap 'build_result=$?; echo "Build failed (exit $build_result). Read $PWD/$log; container $container is retained." >&2; exit "$build_result"' ERR
# Keep an idle container alive; docker exec can change JOBS on every retry.
if docker container inspect "$container" >/dev/null 2>&1; then
  if [ "$(docker inspect --format '{{.Config.Cmd}}' "$container")" != '[sleep infinity]' ]; then
    echo "Container $container uses the older runner; choose a new CONTAINER name." >&2
    exit 1
  fi
  docker update --memory "$memory" --memory-swap "$swap" --cpus "${BUILD_CPUS:-$jobs}" "$container" >> "$log" 2>&1
  docker start "$container" >> "$log" 2>&1
else
  docker run -d --name "$container" --platform linux/arm64 \
    --memory "$memory" --memory-swap "$swap" --cpus "${BUILD_CPUS:-$jobs}" \
    --mount "type=bind,src=$PWD/arm64,dst=/scripts,readonly" \
    --mount "type=bind,src=$PWD/out/arm64,dst=/artifacts" \
    ubuntu:26.04 sleep infinity >> "$log" 2>&1
fi
# flock also prevents overlapping builds against the retained source tree.
docker exec -e "JOBS=$jobs" "$container" \
  flock -n /tmp/hhvm-build.lock bash /scripts/build-container.sh >> "$log" 2>&1
docker exec -e "JOBS=$jobs" "$container" \
  flock -n /tmp/hhvm-build.lock bash /scripts/build-watchman.sh >> "$log" 2>&1
for target in basic full; do
  docker buildx build --platform linux/arm64 --file arm64/Dockerfile \
    --target "$target" --tag "hhvm-$target:$tag" --load . >> "$log" 2>&1
done
echo "Built hhvm-basic:$tag and hhvm-full:$tag"
