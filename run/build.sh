#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run/build.sh [options]

Build HHVM from the HHVM repository's native Docker-compatible build script.

Options:
  --hhvm-ref REF        Required. HHVM git ref to build.
  --docker-tag TAG      Required. Tag images as DOCKER_USER/hhvm-xxxx:TAG.

  --docker-user USER    Docker repository namespace. Default: hersheltheodorelayton.
  --repo URL            HHVM git repository URL. Default: https://github.com/hershel-theodore-layton/hhvm.git
  --single-threaded     Compile with one thread to make build output easier to read.
  --nightly             Build hhvm-nightly packages. Omit for release hhvm packages.
  --builder NAME        Buildx builder name. Default: hhvm_image_builder.
  --out DIR             Export package artifacts to DIR. Default: out.
  -h, --help            Show this help.

Examples:
  run/build.sh --hhvm-ref hhvm-oss-20260605 --docker-tag 26.06.05
  run/build.sh --hhvm-ref hhvm-oss-20260605 --docker-tag 26.06.05 --docker-user yourdockeruser
USAGE
}

repo="https://github.com/hershel-theodore-layton/hhvm.git"
ref=""
single_threaded=""
builder="hhvm_image_builder"
out_dir="out"
is_nightly=""
docker_tag=""
docker_user="hersheltheodorelayton"
ubuntu_image="ubuntu:resolute"
distro="ubuntu-26.04-resolute"
hhvm_build_flag="--ubuntu-26.04"

need_arg() {
  if [ "$#" -lt 2 ] || [ -z "$2" ]; then
    echo "Missing value for $1" >&2
    exit 2
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) need_arg "$@"; repo="$2"; shift 2 ;;
    --hhvm-ref) need_arg "$@"; ref="$2"; shift 2 ;;
    --single-threaded) single_threaded=1; shift ;;
    --docker-tag) need_arg "$@"; docker_tag="$2"; shift 2 ;;
    --docker-user) need_arg "$@"; docker_user="$2"; shift 2 ;;
    --nightly) is_nightly=1; shift ;;
    --builder) need_arg "$@"; builder="$2"; shift 2 ;;
    --out) need_arg "$@"; out_dir="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) break ;;
  esac
done

if [ "$#" -ne 0 ]; then
  echo "Unexpected positional argument: $1" >&2
  usage >&2
  exit 2
fi

if [ -z "$ref" ]; then
  echo "--hhvm-ref is required" >&2
  exit 2
fi

if [ -z "$docker_tag" ]; then
  echo "--docker-tag is required" >&2
  exit 2
fi

log_file="build.$(date +%Y%m%d-%H%M%S).log"
exec > >(tee "$log_file") 2>&1
echo "Logging build output to ${log_file}"

docker buildx inspect "$builder" >/dev/null 2>&1 || docker buildx create \
  --driver-opt env.BUILDKIT_STEP_LOG_MAX_SIZE=-1 \
  --driver-opt env.BUILDKIT_STEP_LOG_MAX_SPEED=-1 \
  --name "$builder" >/dev/null

common_args=(
  --file docker/Dockerfile
  --builder "$builder"
  --progress=plain
  --build-arg "HHVM_REPO=${repo}"
  --build-arg "HHVM_REF=${ref}"
  --build-arg "UBUNTU_IMAGE=${ubuntu_image}"
  --build-arg "DISTRO=${distro}"
  --build-arg "HHVM_BUILD_FLAG=${hhvm_build_flag}"
  --build-arg "IS_NIGHTLY=${is_nightly}"
)

if [ -n "$single_threaded" ]; then
  common_args+=(--build-arg "JOBS=1")
fi
build_artifacts() {
  mkdir -p "$out_dir"
  docker buildx build "${common_args[@]}" \
    --target artifacts \
    --output "type=local,dest=${out_dir}" \
    .
}

build_image() {
  local image_target="$1"
  docker buildx build "${common_args[@]}" \
    --target "$image_target" \
    -t "${docker_user}/hhvm-${image_target}:${docker_tag}" \
    --load \
    .
}

build_artifacts
build_image basic
build_image full
