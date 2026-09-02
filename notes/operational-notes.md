# Operational notes

## Verified state

During the live validation, these conditions were confirmed on this machine:

- `copilot-api` responds at `http://localhost:4141/usage`
- `claude -p 'Responde solo con OK'` works when `ANTHROPIC_BASE_URL` points to the correct proxy
- with a clean port, the direct route was validated with `export ANTHROPIC_BASE_URL=http://localhost:4143`

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

## Valid configuration

```bash
export ANTHROPIC_BASE_URL=http://localhost:4143
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export ANTHROPIC_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4.5
export ANTHROPIC_SMALL_FAST_MODEL=claude-haiku-4.5
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

## Recommendation

When you restart the environment, use the `scripts/start_proxy.sh` script and validate with `curl` + `claude -p 'Responde solo con OK'` before continuing with creative or integration work.
