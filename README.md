# gcs-gitleaks-scan

<p align="center">
  <img alt="gitleaks" src="https://raw.githubusercontent.com/zricethezav/gifs/master/gitleakslogo.png" height="70" />
</p>

A GitHub Composite Action that runs [Gitleaks](https://github.com/gitleaks/gitleaks) secret scanning on your repository using Docker. Detects hardcoded secrets, API keys, tokens, and other sensitive data in your codebase before they are merged or deployed.

> **Stable tag:** Use `partior-libs/gcs-gitleaks-scan@partior-stable` for production workflows.

---

## Overview

Gitleaks is an open-source SAST (Static Application Security Testing) tool that scans Git history and working trees for secrets. This action:

1. Pulls the specified Gitleaks Docker image version.
2. Mounts your `$GITHUB_WORKSPACE` into the container.
3. Runs Gitleaks in `detect` mode with optional custom configuration.
4. On `push` events: scans the full source tree.
5. On `pull_request` events: scans only the commits introduced by the PR (computed from base and HEAD SHAs).
6. Outputs the scan result and exit code for use in downstream steps.

---

## Prerequisites

- **Docker** must be available on the runner (`docker pull` and `docker run` are used).
- `actions/checkout` must run **before** this action in the same job.
- For `pull_request` event correctness, see the [Checkout Requirements](#checkout-requirements) section below.

---

## Minimal Usage

```yaml
name: Secret Scan

on: [push, pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Gitleaks scan
        uses: partior-libs/gcs-gitleaks-scan@partior-stable
```

---

## Custom Configuration

Point the action to your own `.gitleaks.toml` configuration file using the `config-path` input. The path is relative to `$GITHUB_WORKSPACE`.

```yaml
name: Secret Scan with Custom Config

on: [push, pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Gitleaks scan
        id: gitleaks
        uses: partior-libs/gcs-gitleaks-scan@partior-stable
        with:
          config-path: .github/.gitleaks.toml
          gitleaks-version: v8.18.0

      - name: Show scan result
        if: always()
        run: |
          echo "Exit code: ${{ steps.gitleaks.outputs.exitcode }}"
          echo "Result: ${{ steps.gitleaks.outputs.result }}"
```

---

## Checkout Requirements

### For `push` events

A standard `actions/checkout` is sufficient:

```yaml
- uses: actions/checkout@v4
```

### For `pull_request` events

The action computes the commit range between the PR base and HEAD. With the default `fetch-depth: 1`, only the latest commit is available, which may cause the range calculation to fail.

**Use `fetch-depth: 0`** (full history — safest option):

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
```

**Or `fetch-depth: 2`** (minimal, not guaranteed to work for all PRs):

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 2
```

> ⚠️ Using `fetch-depth: 1` (the default) on pull requests **will produce incorrect scan results**. Always set `fetch-depth: 0` or `2` for repositories that run this action on `pull_request` events.

---

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `config-path` | No | `.github/.gitleaks.toml` | Path to the Gitleaks config file, relative to `$GITHUB_WORKSPACE` |
| `gitleaks-version` | No | `v8.12.0` | Gitleaks Docker image tag from `ghcr.io/zricethezav/gitleaks` |

---

## Outputs

| Output | Description |
|--------|-------------|
| `result` | Full Gitleaks log output from the scan |
| `exitcode` | Human-readable result: `✅ Gitleaks scan passed` (clean) or `❌ Gitleaks scan failed — secrets detected` (leaks found) |

### Checking Outputs in Subsequent Steps

```yaml
- name: Run Gitleaks
  id: gitleaks
  uses: partior-libs/gcs-gitleaks-scan@partior-stable

- name: Fail workflow if leaks found
  if: contains(steps.gitleaks.outputs.exitcode, '❌')
  run: |
    echo "Secret scan failed!"
    echo "${{ steps.gitleaks.outputs.result }}"
    exit 1
```

---

## Custom Rules via `extend.toml`

The repository ships a `config/extend.toml` with additional detection rules not present in the default Gitleaks ruleset. Currently includes:

- **AWS Access Key** — extended pattern for detecting AWS access key formats.

To extend the configuration further, add rules in TOML format to `config/extend.toml` or in your own `.gitleaks.toml` using the `[extend]` stanza:

```toml
# .gitleaks.toml
title = "My Custom Gitleaks Config"

[extend]
useDefault = true
path = ".github/extend.toml"

[[rules]]
id = "my-custom-secret"
description = "Detects My Custom Token"
regex = '''MY_TOKEN_[A-Z0-9]{32}'''
tags = ["key", "custom"]
```

---

## Suppressing False Positives

Use a `.gitleaksignore` file at the repository root to suppress specific findings. Each line is a fingerprint of a finding to ignore (generated from the Gitleaks report).

```
# .gitleaksignore
# Format: <rule-id>:<file-path>:<secret-hash>
aws-access-key:config/test-fixtures/sample.env:abc123def456
```

To generate a `.gitleaksignore` entry, run Gitleaks locally with `--report-format json`, identify the false positive, and add its fingerprint.

> The `.gitleaksignore` file in this repository is used to suppress findings from the action's own self-scan.

---

## How It Works

### Docker Execution

The action uses the official Gitleaks Docker image:

```
docker pull ghcr.io/zricethezav/gitleaks:<version>
docker run -v $GITHUB_WORKSPACE:/path ghcr.io/zricethezav/gitleaks detect \
  --source=/path \
  --config=/path/<config-path> \
  --verbose \
  --redact
```

The `--redact` flag masks secret values in output logs to prevent accidental exposure.

### PR Commit Range

For `pull_request` events, `scripts/start-scan.sh` uses `$GITHUB_BASE_SHA` and `$GITHUB_HEAD_SHA` to construct a `--log-opts` range, limiting the scan to only the commits introduced by the PR:

```bash
gitleaks detect --source=/path --log-opts="${BASE_SHA}..${HEAD_SHA}"
```

---

## Project Structure

```
gcs-gitleaks-scan/
├── action.yml                    # Composite action definition
├── .gitleaks.toml                # Self-scan config for this repository
├── .gitleaksignore               # False positive suppressions for self-scan
├── LICENSE
├── LICENSE.md
├── config/
│   └── extend.toml               # Extended detection rules (e.g., AWS access key)
├── sample-data/                  # Sample data for testing rules
└── scripts/
    └── start-scan.sh             # Main scan script (handles push vs PR logic)
```

---

## Contributing

1. Fork the repository and create a feature branch.
2. Add new rules to `config/extend.toml` following existing TOML format.
3. Test rule changes against `sample-data/` fixtures.
4. Open a pull request with a description of the secret pattern being detected.

---

## License

See [LICENSE](LICENSE) / [LICENSE.md](LICENSE.md).
