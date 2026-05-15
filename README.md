# gcs-gitleaks-scan
> GitHub Composite Action for detecting secrets and sensitive data in Git history and code changes using [Gitleaks](https://github.com/gitleaks/gitleaks).

<p align="center">
  <img alt="gitleaks" src="https://raw.githubusercontent.com/zricethezav/gifs/master/gitleakslogo.png" height="70" />
</p>

## Overview
`gcs-gitleaks-scan` runs Gitleaks on `push` and `pull_request` events to detect hardcoded secrets, tokens, API keys, and other sensitive data committed to the repository. It pulls the official Gitleaks Docker image (`ghcr.io/zricethezav/gitleaks`) at a pinned version, executes the scan, and exposes the scan result and exit code as action outputs.

A custom Gitleaks configuration file (`.gitleaks.toml` or `.github/.gitleaks.toml`) can be supplied via the `config-path` input to extend or override the default ruleset.

## Usage

### Default scan
```yaml
name: Gitleaks Secret Scan

on: [push, pull_request]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: partior-libs/gcs-gitleaks-scan@partior-stable
```

### With custom configuration
```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0

- uses: partior-libs/gcs-gitleaks-scan@partior-stable
  with:
    config-path: security/.gitleaks.toml
```
> `config-path` is relative to `$GITHUB_WORKSPACE`.

### Pin a specific Gitleaks version
```yaml
- uses: partior-libs/gcs-gitleaks-scan@partior-stable
  with:
    gitleaks-version: v8.18.0
```

### Capture outputs for downstream steps
```yaml
- uses: partior-libs/gcs-gitleaks-scan@partior-stable
  id: gitleaks
  with:
    config-path: .github/.gitleaks.toml

- name: Handle scan result
  if: steps.gitleaks.outputs.exitcode != '0'
  run: |
    echo "Secrets found! Review output:"
    echo "${{ steps.gitleaks.outputs.result }}"
    exit 1
```

## Inputs
| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `config-path` | No | `.github/.gitleaks.toml` | Path to the Gitleaks config file, relative to `$GITHUB_WORKSPACE`. |
| `gitleaks-version` | No | `v8.12.0` | Version of the Gitleaks Docker image to pull and run. |

## Outputs
| Output | Description |
|--------|-------------|
| `result` | Full Gitleaks log output from the scan. |
| `exitcode` | Exit code from the Gitleaks process (`0` = no secrets found, non-zero = secrets found or scan error). |

## Prerequisites
- **`actions/checkout` with `fetch-depth: 0`** (or at minimum `fetch-depth: 2`). A shallow clone will cause Gitleaks to scan an incomplete history.
- Docker must be available on the runner (required to pull and run the Gitleaks image).
- A `.gitleaks.toml` configuration file in the repository (optional but recommended); the default config path is `.github/.gitleaks.toml`.

### Checkout depth warning
```yaml
# Correct — full history
- uses: actions/checkout@v4
  with:
    fetch-depth: 0

# Also acceptable — but may miss some PR commits
- uses: actions/checkout@v4
  with:
    fetch-depth: 2
```

## Custom Rules
Extend the default ruleset by creating `.github/.gitleaks.toml` in your repository. See `config/extend.toml` in this repository for the Partior-specific rule extensions.

## Contributing
```
git commit -m "<TICKET_NUMBER> <COMMIT_MESSAGE>"
```

## License
See [LICENSE.md](LICENSE.md) and [LICENSE](LICENSE).
