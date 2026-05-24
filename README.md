# cluster-start

Small, opinionated bootstrap repo for getting my development environment ready on a fresh Linux cluster.

The goal is not to be a full dotfiles framework. This is just enough automation to avoid copying configs from old machines, manually downloading the same CLI tools, and realizing later that one small script or alias is missing.

## What It Does

`main.sh` bootstraps a minimal working environment:

- appends the repo's Bash bootstrap block to `~/.bashrc`
- symlinks config directories from `configs/` into `~/.config`
- symlinks executable scripts from `scripts/` into `~/.local/bin`
- downloads CLI tools listed in `manifest.json`
- runs any special install commands listed in `manifest.json`
- validates that expected tools and local scripts are available on `PATH`

The script is designed to be rerunnable. Existing config or script targets are left alone when they already point to this repo; conflicting targets are moved aside with a timestamp before new symlinks are created.

## Assumptions

This repo intentionally keeps a narrow target:

- x86_64 GNU/Linux
- Bash shell
- network access during bootstrap
- `manifest.json` is trusted and maintained by me
- downloaded archives contain the expected Linux binaries

The manifest can run arbitrary commands through `special_cases.command[]`, so do not treat it as untrusted input.

## Prerequisites

The target machine should already have:

```text
bash
curl
find
jq
mktemp
tar
wget
```

## Usage

Review the repo contents first:

```bash
ls configs scripts
cat manifest.json
```

Then run:

```bash
./main.sh
```

After the script completes, load the new shell config in the current terminal:

```bash
source ~/.bashrc
```

New shells should pick it up automatically.

## Layout

```text
.
├── configs/       # config directories and Bash bootstrap block
├── scripts/       # local executable helper scripts
├── manifest.json  # external tools and special install commands
└── main.sh        # bootstrap entrypoint
```

## Notes

This project deliberately avoids heavier tooling like Ansible or a dotfiles manager. Symlinking back to the repo keeps updates simple: pull the latest repo changes, rerun `./main.sh`, and keep moving.

There are still rough edges by design. External tools are downloaded again on each run, and archive extraction currently copies executable files found inside the downloaded archives into `~/.local/bin`. For this repo's current scope, the final validation step is the guardrail.
