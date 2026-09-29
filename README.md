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
