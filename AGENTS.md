# AGENTS.md — gcs-gitleaks-scan

## Repository Overview

`gcs-gitleaks-scan` is a **GitHub Composite Action** that runs [Gitleaks](https://github.com/gitleaks/gitleaks) secret scanning via Docker. It supports both `push` and `pull_request` events with appropriate scan strategies for each.

**Status:** Production-ready. Use the `partior-stable` tag for stable builds.

---

## Architecture

```
gcs-gitleaks-scan/
├── action.yml              # Composite action definition
├── .gitleaks.toml          # Self-scan configuration
├── .gitleaksignore         # Fingerprints of known false positives
├── config/
│   └── extend.toml         # Extended Gitleaks rules
├── sample-data/            # Test fixtures for rule validation
└── scripts/
    └── start-scan.sh       # Core scan logic (push vs PR detection)
```

### Execution Flow

```
action.yml
  │
  ├─ docker pull ghcr.io/zricethezav/gitleaks:<gitleaks-version>
  │
  └─ scripts/start-scan.sh
        │
        ├─ [if GITHUB_EVENT_NAME == push]
        │     docker run gitleaks detect --source=/path --verbose --redact
        │
        ├─ [if GITHUB_EVENT_NAME == pull_request]
        │     Compute BASE_SHA and HEAD_SHA from $GITHUB_BASE_SHA / $GITHUB_HEAD_SHA
        │     docker run gitleaks detect --source=/path --log-opts="${BASE_SHA}..${HEAD_SHA}"
        │
        ├─ Capture exit code from docker run
        │     exit 0 → set output exitcode=✅ Gitleaks scan passed
        │     exit 1 → set output exitcode=❌ Gitleaks scan failed — secrets detected
        │
        └─ Write Gitleaks log to output `result` via $GITHUB_OUTPUT
```

---

## Script Details

### `scripts/start-scan.sh`

Key responsibilities:
1. Determines event type from `$GITHUB_EVENT_NAME`.
2. Constructs the `docker run` command with the correct volume mount (`-v $GITHUB_WORKSPACE:/path`).
3. Passes the config path as `-v`-mounted file inside the container: `--config=/path/<config-path>`.
4. For PR events: extracts commit range from `$GITHUB_BASE_SHA` and `$GITHUB_HEAD_SHA`.
5. Captures stdout/stderr from Gitleaks for the `result` output.
6. Maps Docker exit code to the human-readable `exitcode` output.
7. Writes both outputs to `$GITHUB_OUTPUT`.

### `config/extend.toml`

Additional Gitleaks detection rules appended to the default ruleset. Currently:
- **AWS Access Key**: Extended regex for detecting AWS access key ID format variations.

Rule format:
```toml
[[rules]]
id = "aws-access-key-extended"
description = "AWS Access Key (extended)"
regex = '''(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'''
tags = ["key", "AWS"]
```

---

## Making Changes

### Updating the Default Gitleaks Version

Change the `default` value of the `gitleaks-version` input in `action.yml`:

```yaml
inputs:
  gitleaks-version:
    description: 'Gitleaks Docker image version'
    required: false
    default: 'v8.18.0'   # Update this value
```

Always test the new version against `sample-data/` fixtures before changing the default.

### Adding a New Detection Rule

1. Add the rule to `config/extend.toml` following the existing TOML `[[rules]]` format.
2. Add a corresponding test fixture to `sample-data/` that the rule should detect.
3. Verify locally:

```bash
docker run --rm \
  -v $(pwd):/path \
  ghcr.io/zricethezav/gitleaks:v8.12.0 \
  detect --source=/path --config=/path/config/extend.toml --verbose
```

4. If the new rule produces false positives in this repository's own code, add the fingerprint to `.gitleaksignore`.

### Handling a New Event Type

Currently only `push` and `pull_request` are handled in `start-scan.sh`. To add support for `workflow_dispatch` or `schedule`:
- These events behave like `push` (no commit range), so the push branch in `start-scan.sh` can be reused.
- Add the event to the condition check in the script.

---

## Important Constraints

### Docker Requirement

The runner **must have Docker available**. This action is not compatible with runners that do not have Docker installed (e.g., some self-hosted minimal runners). The `ubuntu-latest` GitHub-hosted runner includes Docker.

### `fetch-depth` for Pull Requests

The `start-scan.sh` script relies on `$GITHUB_BASE_SHA` being reachable in the local Git history. With the default `fetch-depth: 1`, only the HEAD commit is fetched, making the base SHA unreachable.

**Always require `fetch-depth: 0` (or at minimum `2`) in documentation and examples** for workflows that include `pull_request` events.

### `--redact` Flag

The Gitleaks `--redact` flag is always passed. This masks secret values in output logs, replacing them with `REDACTED`. This is intentional — it prevents secrets from appearing in GitHub Actions logs even when a leak is detected.

If you need to see the actual secret value for investigation, run Gitleaks locally without `--redact`.

### Output: `exitcode` vs actual exit code

The action captures the Docker container's exit code and maps it to a human-readable string output (`exitcode`). The action step itself does **not** fail automatically when leaks are found — callers must inspect `steps.<id>.outputs.exitcode` and fail themselves if desired. This gives calling workflows flexibility in how they handle findings.

---

## Self-Scan Configuration

This repository scans itself using:
- `.gitleaks.toml` — limits scan scope to avoid false positives from test fixtures and sample data.
- `.gitleaksignore` — fingerprints of known false positives (e.g., example tokens in documentation).

The self-scan runs via `.github/workflows/gitleaks.yml`.

---

## Workflows

| Workflow | Purpose |
|----------|---------|
| `gitleaks.yml` | Self-scan of this repository |
| `ci-workflow.yaml` | Continuous integration tests |
| `tag-partior-stable.yml` | Tags the `partior-stable` ref on merge to main |

---

## Testing Changes Locally

```bash
# Clone and enter the repo
cd gcs-gitleaks-scan

# Run a detect scan on the current workspace
docker run --rm \
  -v $(pwd):/path \
  ghcr.io/zricethezav/gitleaks:v8.12.0 \
  detect \
  --source=/path \
  --config=/path/.gitleaks.toml \
  --verbose \
  --redact

# Test with the extended config
docker run --rm \
  -v $(pwd):/path \
  ghcr.io/zricethezav/gitleaks:v8.12.0 \
  detect \
  --source=/path \
  --config=/path/config/extend.toml \
  --verbose
```

---

## References

- [Gitleaks GitHub Repository](https://github.com/gitleaks/gitleaks)
- [Gitleaks Configuration Reference](https://github.com/gitleaks/gitleaks#configuration)
- [Gitleaks Docker Image](https://github.com/gitleaks/gitleaks/pkgs/container/gitleaks)
- [GitHub Actions `GITHUB_OUTPUT`](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-an-output-parameter)
