# Local Claude with Copilot

This project documents the local setup used to run Claude Code through a GitHub Copilot-compatible proxy based on `copilot-api`, without depending directly on the Anthropic public API.

## Reference

- Original guide: https://dev.to/allentcm/using-claude-code-with-github-copilot-subscription-2obj

## Goal

The aim is to keep a local, controlled, and reproducible flow where:

1. `copilot-api` exposes a local OpenAI/Anthropic-compatible endpoint.
2. `claude` points to that local endpoint.
3. The proxy translates the request to GitHub Copilot.
4. The client uses local environment variables such as `ANTHROPIC_BASE_URL` and a dummy token for local testing.

This allows Claude Code to behave like an Anthropic client while the real execution happens through Copilot.

## Minimal architecture

```text
Claude Code
   │
   ├── env: ANTHROPIC_BASE_URL=http://localhost:4141
   ├── env: ANTHROPIC_AUTH_TOKEN=sk-dummy
   ├── env: ANTHROPIC_MODEL=claude-sonnet-5
   │
   ▼
Local proxy (copilot-api)
   │
   ├── exposes /v1/chat/completions, /messages, /usage
   │
   ▼
GitHub Copilot
   │
   └── returns the real response
```

## Tested environment

These variables were used during live validation:

```bash
export ANTHROPIC_BASE_URL=http://localhost:4143
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export ANTHROPIC_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4.5
export ANTHROPIC_SMALL_FAST_MODEL=claude-haiku-4.5
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

For Aider or OpenAI-compatible clients:

```bash
export OPENAI_API_BASE=http://localhost:4141/v1
export OPENAI_API_KEY=sk-1234
```

## What had to be watched carefully

During setup, several critical points appeared:

- stale ports or zombie processes can hide the real failure
- old shell exports can keep pointing to the wrong URL
- `claude` rejects conversations ending with an `assistant` turn
- Aider working does not prove Claude works without a real direct check

## Start the proxy

The simplest path is to run the project launcher:

```bash
bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
```

The script:

- validates that `copilot-api` exists in PATH
- clears stale listeners on the target port
- starts the proxy with `copilot-api start -p 4141`
- waits for the `/usage` endpoint to respond
- leaves the local service ready for Claude or Aider

## Health check

Before assuming it works, always validate:

```bash
curl -sS http://localhost:4141/usage
```

If it returns JSON, the proxy is alive.

## Recommended real validation

This is the minimal end-to-end check:

```bash
export ANTHROPIC_BASE_URL=http://localhost:4141
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export ANTHROPIC_MODEL=claude-sonnet-5
claude -p 'Responde solo con OK'
```

Expected output:

```text
OK
```

## Project documentation index

- [docs/README.md](docs/README.md): markdown index for the project
- [docs/quickstart.md](docs/quickstart.md): fast setup guide
- [docs/troubleshooting.md](docs/troubleshooting.md): frequent issues and fixes
- [notes/operational-notes.md](notes/operational-notes.md): validated operational notes
- [i18n/en/README.md](i18n/en/README.md): English reference
- [i18n/es/README.md](i18n/es/README.md): Spanish reference retained for continuity
- [env.example](env.example): local environment template
- [scripts/start_proxy.sh](scripts/start_proxy.sh): robust startup script

## Rules for future agents

- never assume a fix works without executing a real command
- always validate with `curl` and then with the actual client
- check the port, process, and current environment before restarting blindly
- keep a single, reproducible startup flow

## Final note

This local setup exists to keep Claude Code usable with GitHub Copilot while preserving a local, auditable, and easy-to-rebuild workflow. The project is intentionally documented so a future agent can reconstruct the environment without losing the debugging context.
