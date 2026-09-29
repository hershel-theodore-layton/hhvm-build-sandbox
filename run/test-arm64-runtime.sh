#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
builder=${CONTAINER:-hhvm-arm64-build}
tag=${IMAGE_TAG:-26.09.29-arm64}
volume=${TEST_VOLUME:-hhvm-arm64-test-source}
stamp=$(date +%Y%m%d-%H%M%S)
helper="hhvm-arm64-test-copy-$stamp"
mkdir -p logs
copy_log="logs/runtime-copy-$stamp.log"
docker volume create "$volume" > "$copy_log" 2>&1
docker create --name "$helper" --platform linux/arm64 \
  --mount "type=volume,src=$volume,dst=/hhvm/hphp/test" \
  "hhvm-basic:$tag" sleep infinity >> "$copy_log" 2>&1
trap 'docker rm "$helper" >/dev/null 2>&1 || true' EXIT
# Preserve case-sensitive source filenames in Docker's Linux filesystem.
docker cp "$builder:/usr/src/hhvm/hphp/test/." - 2>> "$copy_log" | \
  docker cp - "$helper:/hhvm/hphp/test" >> "$copy_log" 2>&1
for target in basic full; do
  for mode in interp jit; do
    name="hhvm-arm64-quick-$target-$mode-$stamp"
    log="logs/quick-$target-$mode-$stamp.log"
    echo "Test output: $PWD/$log"
    # Permission tests must run without root's DAC override privileges.
    if docker run --name "$name" --platform linux/arm64 \
      --user 65534:65534 --memory 4g --memory-swap 4g --cpus 4 --ulimit core=0 \
      --mount "type=volume,src=$volume,dst=/hhvm/hphp/test,readonly" \
      -e HHVM_BIN=/usr/bin/hhvm "hhvm-$target:$tag" \
      /hhvm/hphp/test/run --threads 4 -m "$mode" /hhvm/hphp/test/quick \
      > "$log" 2>&1; then
      docker rm "$name" >> "$log" 2>&1
    else
      echo "Tests failed; read $PWD/$log. Container $name is retained." >&2
      exit 1
    fi
  done
done
echo "Quick tests passed in both images with interpreter and JIT."
