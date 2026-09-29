# HHVM Docker Image Builder

> _This repository supersedes `hhvm-build`_

The build is a multi-target Dockerfile:

- `artifacts` exports the generated Debian packages.
- `basic` installs only the generated HHVM package on the selected Ubuntu base.
- `full` starts from `basic` and adds git, PHP/composer, curl/wget/unzip,
  Watchman, and HHVM autoload config.

## Usage

Builds use Ubuntu 26.04. New builders are limited to 12 GiB RAM and 2 GiB swap.
Use `--jobs 4` to limit compilation to four jobs and new builders to four CPUs.

```sh
run/build.sh --help
run/build.sh --hhvm-ref hhvm-oss-20260605 --docker-tag 26.06.05
```

## Native ARM64 build

On an ARM64 Docker host, run `run/build-arm64.sh`. This builds the
`hhvm-oss-20260929-arm` HHVM branch at revision `f976f589b516884b3cac67e6a424801e7840565d`,
exports Debian packages to `out/arm64`, and creates
`hhvm-basic:26.09.29-arm64` and `hhvm-full:26.09.29-arm64` locally.
The full image uses Composer from Ubuntu and builds Watchman v2025.05.26.00
from pinned source for native ARM64 support, including suffix-array autoload
queries unsupported by Ubuntu's older Watchman package. Its bundled libraries
stay private under `/opt/watchman`, avoiding the system-library conflicts
discussed in [Watchman PR #1340](https://github.com/facebook/watchman/pull/1340).

The persistent `hhvm-arm64-build` container defaults to all Docker CPUs,
15 GiB RAM, and 16 GiB combined RAM/swap. Override `JOBS`, `BUILD_CPUS`,
`BUILD_MEMORY`, and `BUILD_MEMORY_SWAP` as needed. `CONTAINER` and `IMAGE_TAG`
customize the container name and output tags. Docker's VM must have enough
memory available for the selected limits.

Output is saved to timestamped files in `logs/` without streaming. Read the
log after the command finishes. Failed containers are retained; rerun to
reuse downloaded dependencies and compiled objects. Builds are locked to
prevent overlapping attempts in the same container. Use a fresh container
when changing the pinned source revision. ARM portability changes are
committed in HHVM itself. Reduced C/C++ debug information limits disk and
memory use.

Run `run/test-arm64.sh` to check both images with JIT enabled and disabled,
including native `.hack` autoloading. It also checks Watchman suffix-array
queries, Hack typechecking, Composer, and Watchman in the full image.

Run `run/test-arm64-runtime.sh` to run the HHVM quick suite in both images,
using the interpreter and JIT. It copies tests from the retained build
container into a case-sensitive Docker volume and runs them as a non-root
user so permission tests behave correctly. Output goes to `logs/`; failed
test containers are retained for diagnosis. These checks do not cover the
full HHVM regression suite. Publishing is a separate operation.

For native autoloading in `basic`, pass
`-d hhvm.autoload.db.path=/var/tmp/hhvm-autoload-%{euid}-%{schema}.db`
and provide a project `.hhvmconfig.hdf`. The full image configures this
database path automatically and also provides Watchman for live queries.

Verified on 2026-09-30: both images report Linux ARM64 and HHVM 26.9.29.
All 862 quick tests pass in each image under both interpreter and JIT
(3,448 test executions). Native autoloading, Watchman suffix-array queries
(including as a non-root user), and Hack typechecking also pass.

## Publishing

Publishing is separate from building and only operates on already-built local
images. Source and explicit destination tags are used exactly as passed to
`--from` and `--to`:

```sh
run/publish.sh --from 26.06.05 --to 26.06.05
run/publish.sh --from 26.06.05 --to-beta
run/publish.sh --from 26.06.05 --to 26.06.05 --docker-user yourdockerusername
```

### Beta tags

The `beta-resolute` tag was published by mistake. It is now maintained as an
alias for `beta` so that users who adopted it can continue to pull updates.
Publishing a beta updates both tags to the same image.

`beta-resolute` will stop receiving updates when the build target moves to
Ubuntu 28.04 or another platform. Use `beta` for the continuing beta channel.

## See Also

- `hershel-theodore-layton/hhvm` branch
  [hhvm-oss-20260605](https://github.com/hershel-theodore-layton/hhvm/commit/e8b37975a048a47fec4de16482e01d2c573b4b6f)
- `hershel-theodore-layton/hhvm` branch
  [hhvm-oss-20260605-resolute-raccoon](https://github.com/hershel-theodore-layton/hhvm/commit/0a1acba1cb9adf2489535d992f0584a62233ed64)
- `hershel-theodore-layton/hhvm-build` branch
  [master](https://github.com/hershel-theodore-layton/hhvm-build/commit/59e00d48b46fa39e669f4e2fb481b8bd95f8830b)
