# Operational notes

## Verified state

During the live validation, these conditions were confirmed on this machine:

- `copilot-api` responds at `http://localhost:4141/usage`
- Claude Code works when `ANTHROPIC_BASE_URL` points to the running proxy and its selected model accepts a real request
- `scripts/start_proxy.sh` checks real model requests and writes a custom `modelPicker` entry using `behavesAs` when it needs a non-Claude Copilot backend
- On the observed `free_limited_copilot` account, Claude model IDs were rejected while `gpt-4.1` worked; the native Claude Code CLI then returned the expected response without an unknown-model warning

## Observed pitfalls

1. stale `ANTHROPIC_BASE_URL` in the shell
2. previous proxy process bound to an occupied port
3. conversation ending in `assistant`
4. assuming Aider works and Claude also works without testing both

## Operation rules

- `curl` before `claude`
- `ps` / `lsof` before restarting
- one port and one terminal at a time
- real proof before closing the issue

## Base configuration

```bash
export ANTHROPIC_BASE_URL=http://localhost:4141
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

## Recommendation

When you restart the environment, use `scripts/start_proxy.sh` and validate with `curl` plus a real `claude -p` request before continuing with other work. The launcher rechecks model support each time. If authorization has expired, complete `copilot-api auth`; if the account has lost Copilot student/premium entitlement, the launcher can only use a fallback model the account still supports.
