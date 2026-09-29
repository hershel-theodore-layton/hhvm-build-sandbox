#!/usr/bin/env bash
# Build a native Watchman with suffix-array queries supported by modern projects.
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
export PATH=/root/.cargo/bin:$PATH
export CC=clang-20 CXX=clang++-20
export CARGO_BUILD_JOBS=${JOBS:-4}
apt-get -o Acquire::Retries=3 update
apt-get -o Acquire::Retries=3 install -y --no-install-recommends git python3 python3-setuptools cmake ninja-build patchelf clang-20 sudo
cd /usr/src
if [ ! -d watchman/.git ]; then
  git clone --depth=1 --branch v2025.05.26.00 https://github.com/facebook/watchman.git
fi
cd watchman
test "$(git rev-parse HEAD)" = 3f9c5700598c843a1fe5df71331c553c67e68171
# Ninja 1.10's bootstrap predates removal of Python's pipes module.
cp /scripts/ninja-python.patch /scripts/mvfst-cstdlib.patch build/fbcode_builder/patches/
python3 - <<'PYTHON'
from pathlib import Path
p = Path('watchman/query/GlobTree.h')
s = p.read_text()
if '#include <cstdint>' not in s:
    p.write_text(s.replace('#pragma once', '#pragma once\n\n#include <cstdint>'))
p = Path('build/fbcode_builder/manifests/ninja')
s = p.read_text()
if 'patchfile = ninja-python.patch' not in s:
    p.write_text(s.replace('builder = ninja_bootstrap',
                           'builder = ninja_bootstrap\npatchfile = ninja-python.patch'))
p = Path('build/fbcode_builder/manifests/mvfst')
s = p.read_text()
if 'patchfile = mvfst-cstdlib.patch' not in s:
    p.write_text(s.replace('builder = cmake',
                           'builder = cmake\npatchfile = mvfst-cstdlib.patch'))
p = Path('build/fbcode_builder/manifests/zlib')
p.write_text(p.read_text().replace('https://zlib.net/zlib-',
                                  'https://zlib.net/fossils/zlib-'))
PYTHON
getdeps=(python3 build/fbcode_builder/getdeps.py --scratch-path /usr/src/watchman-deps --num-jobs "${JOBS:-4}")
"${getdeps[@]}" install-system-deps --recursive watchman
"${getdeps[@]}" build --src-dir=. --project-install-prefix watchman:/opt/watchman --no-tests --extra-cmake-defines '{"CMAKE_POLICY_VERSION_MINIMUM":"3.5","ENABLE_LIBCXX":"OFF"}' watchman
"${getdeps[@]}" fixup-dyn-deps --src-dir=. --project-install-prefix watchman:/opt/watchman --no-tests --extra-cmake-defines '{"CMAKE_POLICY_VERSION_MINIMUM":"3.5","ENABLE_LIBCXX":"OFF"}' --strip watchman /artifacts/watchman --final-install-prefix /opt/watchman
ln -sfn /artifacts/watchman /opt/watchman
/opt/watchman/bin/watchman --version
python3 /scripts/watchman-runtime-deps.py
