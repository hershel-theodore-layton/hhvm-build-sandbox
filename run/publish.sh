#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'USAGE'
Usage:
  run/publish.sh --from TAG (--to TAG | --to-beta)

Publish already-built local HHVM runtime images to Docker Hub.

Options:
  --from TAG     Required. Local source tag for both hhvm-basic and hhvm-full.
  --to TAG       Destination Docker tag for both images.
  --to-beta      Publish both images with the beta Docker tag.

  --docker-user  USER Docker repo namespace. Default: hersheltheodorelayton.
  --ubuntu-26.04 Append -resolute to source and destination image tags.
  -h, --help     Show this help.

Examples:
  run/publish.sh --from 26.06.05 --to 26.06.05
  run/publish.sh --from 26.06.05 --to-beta --ubuntu-26.04
  run/publish.sh --from 26.06.05 --to 26.06.05 --docker-user yourdockeruser
USAGE
}

from_tag=""
to_tag=""
to_beta=""
docker_user="hersheltheodorelayton"
tag_suffix=""

need_arg() {
  if [ "$#" -lt 2 ] || [ -z "$2" ]; then
    echo "Missing value for $1" >&2
    exit 2
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --from) need_arg "$@"; from_tag="$2"; shift 2 ;;
    --to) need_arg "$@"; to_tag="$2"; shift 2 ;;
    --to-beta) to_beta=1; shift ;;
    --docker-user) need_arg "$@"; docker_user="$2"; shift 2 ;;
    --ubuntu-26.04) tag_suffix="-resolute"; shift ;;
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

if [ -z "$from_tag" ]; then
  echo "--from is required" >&2
  exit 2
fi

if [ -n "$to_tag" ] && [ -n "$to_beta" ]; then
  echo "--to and --to-beta are mutually exclusive" >&2
  exit 2
fi

if [ -z "$to_tag" ] && [ -z "$to_beta" ]; then
  echo "Either --to or --to-beta is required" >&2
  exit 2
fi

if [ -n "$to_beta" ]; then
  to_tag="beta"
fi

append_suffix() {
  local tag="$1"
  if [ -n "$tag_suffix" ] && [[ "$tag" != *"$tag_suffix" ]]; then
    printf '%s%s\n' "$tag" "$tag_suffix"
  else
    printf '%s\n' "$tag"
  fi
}

from_tag="$(append_suffix "$from_tag")"
to_tag="$(append_suffix "$to_tag")"

for image_format in basic full; do
  src="${docker_user}/hhvm-${image_format}:${from_tag}"
  dest="${docker_user}/hhvm-${image_format}:${to_tag}"

  docker image inspect "$src" >/dev/null
  docker tag "$src" "$dest"
  docker push "$dest"
done
