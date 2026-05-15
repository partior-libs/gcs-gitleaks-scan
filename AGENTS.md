# AGENTS.md — gcs-gitleaks-scan

## Purpose
`gcs-gitleaks-scan` is a GitHub Composite Action that wraps the Gitleaks open-source secret scanner. It pulls the official Gitleaks Docker image at a pinned version, mounts the workspace, and runs the scan with an optional custom configuration file. The scan result (log output and exit code) is captured and exposed as action outputs so that caller workflows can conditionally fail or post alerts.

## Repository Map
| File/Dir | Role |
|----------|------|
| `action.yml` | Composite action definition — inputs, outputs, single scan step |
| `scripts/start-scan.sh` | Bash script that orchestrates the `docker pull` and `docker run gitleaks` commands |
| `config/extend.toml` | Partior-specific Gitleaks rule extensions (allowlists, additional patterns) |
| `.gitleaks.toml` | Repository-level Gitleaks configuration for this action's own codebase |
| `sample-data/` | Example files used for local testing of scan rules |
| `LICENSE` | Apache 2.0 (Gitleaks upstream licence) |
| `LICENSE.md` | Partior licence addendum |
| `README.md` | Human-facing documentation with sample workflows |

## Tech Stack
- GitHub Actions composite action runtime
- Bash (`scripts/start-scan.sh`)
- Docker (`ghcr.io/zricethezav/gitleaks:v8.12.0` by default)
- TOML configuration (Gitleaks rule format)

## Architecture Patterns
- **Docker execution**: Gitleaks runs inside Docker to provide a version-pinned, reproducible scan environment without requiring Gitleaks to be pre-installed on the runner.
- **Script delegation**: `action.yml` passes `config-path` and `gitleaks-version` to `scripts/start-scan.sh`; all Docker orchestration lives in the script.
- **Exit-code pass-through**: the Docker exit code is captured and exposed via `$GITHUB_OUTPUT` so callers can implement their own failure logic.
- **Configurable rules**: the `config-path` input allows any repository to override or extend the default Gitleaks ruleset without forking this action.

## Development Commands
```bash
# Validate action YAML
python3 -c "import yaml, sys; yaml.safe_load(open('action.yml'))"

# Lint shell script
shellcheck scripts/start-scan.sh

# Run scan locally (Docker required)
docker pull ghcr.io/zricethezav/gitleaks:v8.12.0
bash scripts/start-scan.sh ".github/.gitleaks.toml" "v8.12.0"

# Test against sample data
docker run --rm -v "$(pwd):/repo" ghcr.io/zricethezav/gitleaks:v8.12.0 \
  detect --source /repo/sample-data --config /repo/config/extend.toml
```

## Environment Setup
- Docker Engine 20.10+ on the runner.
- `actions/checkout` with `fetch-depth: 0` (full history required for accurate historical scan).
- No additional secrets required for the scan itself.

## Coding Conventions
- Shell: `set -euo pipefail` in `start-scan.sh`.
- Docker commands must specify the exact image tag (never `latest`).
- Exit codes: `0` = clean, `1` = secrets found, `2` = scan error — document all three in output descriptions.
- TOML rule files: follow Gitleaks v8 configuration schema; include comments for every custom rule explaining its purpose.

## Testing
- Test with `sample-data/` containing known-bad patterns to confirm rules fire correctly.
- Test with a clean repository to confirm zero false positives.
- Test `config-path` override by pointing to `config/extend.toml` and verifying custom rules are applied.
- Verify that `exitcode` output is correctly populated for both pass (0) and fail (non-0) outcomes.

## Key Abstractions
- **`start-scan.sh`**: the single point of truth for how Gitleaks is invoked; changing scan flags should happen here.
- **`gitleaks-version` input**: the pin that controls which Gitleaks release is used; bump intentionally after testing.
- **`config-path` input**: the extension mechanism for per-repository rule customisation.

## Agentic Task Guidance
✅ Safe: bump `gitleaks-version` default after testing the new version against `sample-data/`  
✅ Safe: add new rules to `config/extend.toml`; add new sample data files  
⚠️ Caution: changing `config-path` default (`.github/.gitleaks.toml`) — existing repos rely on that path  
⚠️ Caution: adding allowlist rules — ensure they do not suppress legitimate secrets  
❌ Never: set the Docker image to `latest` — pinned versions are required for reproducibility  
❌ Never: ignore non-zero exit codes from the Gitleaks scan — they indicate detected secrets  

## External Dependencies
- `ghcr.io/zricethezav/gitleaks` Docker image (GitHub Container Registry)
- Docker Engine on the runner
- `actions/checkout@v4` (caller responsibility — must use `fetch-depth: 0`)
- `partior-stable` tag for stable production releases

## Common Pitfalls
- `fetch-depth: 1` (GitHub Actions default) causes Gitleaks to scan only the tip commit, missing history leaks — always require `fetch-depth: 0`.
- Docker socket permissions on self-hosted runners — the runner user must be in the `docker` group.
- Large repositories with long histories can make the scan slow; consider `--log-opts` to limit the commit range on very busy branches.
- Gitleaks v8 changed the config schema from v7 — do not mix v7 and v8 TOML syntax in `extend.toml`.
