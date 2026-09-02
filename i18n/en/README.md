# Local Claude with Copilot

English reference for the local Claude + GitHub Copilot compatibility setup.

## What this project contains

- setup notes for the local proxy
- environment template for Claude and Aider
- startup script for `copilot-api`
- troubleshooting notes for common runtime errors
- validated operational notes for future agents

## Related documents

- [../../README.md](../../README.md)
- [../../docs/README.md](../../docs/README.md)
- [../../docs/quickstart.md](../../docs/quickstart.md)
- [../../docs/troubleshooting.md](../../docs/troubleshooting.md)
- [../../notes/operational-notes.md](../../notes/operational-notes.md)
- [../../scripts/start_proxy.sh](../../scripts/start_proxy.sh)
- [../../env.example](../../env.example)

## Quick summary

This project keeps Claude Code working through a local `copilot-api` proxy. The client points to a local Anthropic-compatible endpoint, and the proxy forwards the request to GitHub Copilot. This lets teams keep a reproducible local workflow while preserving a clear verification path.
