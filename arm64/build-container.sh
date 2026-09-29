#!/usr/bin/env bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
export JOBS=${JOBS:-$(nproc)}
export CARGO_BUILD_JOBS=$JOBS OPAMJOBS=$JOBS
export CMAKE_BUILD_PARALLEL_LEVEL=$JOBS DEB_BUILD_OPTIONS="parallel=$JOBS"
export HHVM_DISABLE_NUMA=true HHVM_DISABLE_PERSONALITY=true
export OUT=/artifacts DISTRO=ubuntu-26.04-resolute LLVM_VERSION=20
export PATH=/root/.cargo/bin:$PATH
apt-get update
apt-get install -y --no-install-recommends ca-certificates git python3
cd /usr/src
if [ ! -d hhvm/.git ]; then
  git clone --depth=1 --single-branch --branch hhvm-oss-20260929-arm https://github.com/hershel-theodore-layton/hhvm.git
fi
cd hhvm
test "$(git rev-parse HEAD)" = f256e93a1a1080c4b9dc1b802ee7412c542d345a
# Recover an interrupted initial checkout after a Docker restart.
if [ ! -f hphp/runtime/version.h ]; then
  git reset --hard HEAD
fi
export HHVM_INCREMENTAL_BUILD=1
export HHVM_VERSION=$(awk '/^# define HHVM_VERSION_MAJOR / { major=$4 } /^# define HHVM_VERSION_MINOR / { minor=$4 } /^# define HHVM_VERSION_PATCH / { patch=$4 } END { print major "." minor "." patch }' hphp/runtime/version.h)
./build.sh --ubuntu-26.04
