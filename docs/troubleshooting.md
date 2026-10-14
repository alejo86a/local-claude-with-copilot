# Troubleshooting

## 1) The proxy does not respond

Check the port and the process first:

```bash
lsof -nP -iTCP:4141 -sTCP:LISTEN || true
ps -ef | grep copilot-api | grep -v grep || true
curl -I http://localhost:4141/usage
```

If there is a stale process or the port is occupied:

```bash
pkill -f 'copilot-api' || true
bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
```

## 2) Connection refused

This usually means the proxy is not running or your terminal still has stale environment variables.

Check:

```bash
echo $ANTHROPIC_BASE_URL
curl -I http://localhost:4141/usage
```

If it does not respond, restart the proxy.

## 3) Stale environment variables

A common issue is that a terminal previously exported the wrong URL and keeps using that config even when the new proxy is working.

Solution:

```bash
unset ANTHROPIC_BASE_URL
export ANTHROPIC_BASE_URL=http://localhost:4141
```

Or open a fresh terminal and re-export everything.

## 4) The client fails even though the proxy responds

Two things must be distinguished:

- the proxy is alive
- the client is pointing to the correct port

Check both with `curl` and the actual client command:

```bash
curl -sS http://localhost:4141/usage
claude -p 'Responde solo con OK'
```

## 5) Final conversation error with `assistant`

This is a classic Anthropic client issue when the history ends with an `assistant` turn instead of a `user` turn.

Rule: the last message in the conversation must be `user`.

If you see errors like:

```text
This model does not support assistant message prefill. The conversation must end with a user message.
```

then clear the conversation history before sending the request or start a fresh session.

## 6) Model not recognized or unavailable

`/v1/models` may advertise model IDs that the current GitHub Copilot account cannot actually use. The startup script sends minimal real requests and updates `~/.claude/settings.json` only after a request succeeds. For a non-Claude backend, it creates a custom `modelPicker` entry with a known Claude capability profile (`behavesAs`) so Claude Code accepts the provider model without an unknown-model warning.

The account may have lost its student or paid Copilot entitlement. Check the plan and quotas:

```bash
copilot-api check-usage
```

The `free_limited_copilot` plan has no premium interactions in the observed setup. Claude-backed models may therefore be rejected even while included chat models work. The launcher falls back to `gpt-4.1` or `gpt-4o` when available. Claude Code remains the client, but those requests use a GPT model.

If the GitHub session itself is expired, refresh it with `copilot-api auth`, complete the browser device login, then rerun:

```bash
bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
claude -p 'Reply with exactly: CLAUDE_CONNECTION_OK'
```

If every Claude and fallback model fails, the account currently has no usable model entitlement through this proxy. A model name change alone cannot grant access; restore the student/paid Copilot entitlement or use an eligible model/provider.

## 7) Do not declare success without a real test

The most important rule in this project is:

- do not rely only on a config file
- do not assume the proxy is healthy just because it looks correct
- run a real verification using `claude` or `aider`

Minimum validation command:

```bash
claude -p 'Responde solo con OK'
```

If it does not return `OK`, it is not considered resolved.
