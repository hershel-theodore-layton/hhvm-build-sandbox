#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
tag=${IMAGE_TAG:-26.09.29-arm64}
for target in basic full; do
  image="hhvm-$target:$tag"
  test "$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "$image")" = linux/arm64
  docker run --rm --platform linux/arm64 --memory 2g --memory-swap 2g "$image" hhvm --version
  for jit in false true; do
    echo "Testing $image with JIT=$jit"
    docker run --rm --platform linux/arm64 --memory 2g --memory-swap 2g \
      --mount "type=bind,src=$PWD/arm64/smoke.hack,dst=/tmp/smoke.hack,readonly" \
      "$image" hhvm -vEval.Jit="$jit" -vEval.JitPGO=false /tmp/smoke.hack
  done
  docker run --rm --platform linux/arm64 --memory 2g --memory-swap 2g \
    --mount "type=bind,src=$PWD/arm64/autoload,dst=/fixtures,readonly" \
    "$image" sh -ec '
      cp -R /fixtures /tmp/autoload-test
      cd /tmp/autoload-test
      for jit in false true; do
        hhvm -d hhvm.autoload.db.path=/tmp/autoload-test.db \
          -vEval.Jit="$jit" -vEval.JitPGO=false main.hack
      done'
done
# Exercise the full image defaults with a modern Watchman suffix-array query.
docker run --rm --platform linux/arm64 --memory 2g --memory-swap 2g \
  --mount "type=bind,src=$PWD/arm64/autoload,dst=/fixtures,readonly" \
  "hhvm-full:$tag" sh -ec '
    cp -R /fixtures /tmp/autoload-watchman
    cd /tmp/autoload-watchman
    cp watchman.hdf .hhvmconfig.hdf
    for jit in false true; do
      hhvm -vEval.Jit="$jit" -vEval.JitPGO=false main.hack
    done
    timeout 120 hh_client check .
    hh_client stop .'

docker run --rm --platform linux/arm64 --memory 2g --memory-swap 2g \
  "hhvm-full:$tag" sh -ec 'hh_client --version; composer --version; watchman --version'
