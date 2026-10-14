# Quickstart

## 1) Start the local proxy

```bash
bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
```

The script does this automatically:

- checks that `copilot-api` is installed
- reuses a healthy proxy or replaces a stale `copilot-api` listener
- starts `copilot-api start -p 4141`
- waits for `/usage` to respond
- reads the proxy model catalog and probes real Claude requests
- maps Claude Code's recognized Sonnet, Haiku, and Opus IDs to backends that accept real requests

If GitHub authorization has expired, refresh it with `copilot-api auth`, complete the browser sign-in, then run the startup script again.

If the account no longer has access to Claude models, the launcher tries the proxy-documented `gpt-4.1` and `gpt-4o` backends. Claude Code remains the native client, but the underlying model is then GPT, not Claude. Restoring Claude-backed models requires Copilot entitlement that includes them. The launcher writes a custom model-picker entry with Claude-compatible capability defaults and the explicitly labeled Copilot backend ID.

## 2) Verify that the proxy is alive

```bash
curl -sS http://localhost:4141/usage
```

If it returns JSON, the proxy is running.

## 3) Export Claude environment variables

```bash
export ANTHROPIC_BASE_URL=http://localhost:4141
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

The startup script determines usable models at runtime; do not assume a model name shown by `/v1/models` is accepted until a real request succeeds.

## 4) Test a real request

```bash
claude -p 'Responde solo con OK'
```

Expected output:

```text
OK
```

## 5) For Aider or OpenAI-compatible clients

```bash
export OPENAI_API_BASE=http://localhost:4141/v1
export OPENAI_API_KEY=sk-1234
```

Then:

```bash
aider --model openai/claude-sonnet-5
```

## 6) If you want to test on a clean port

Sometimes it is useful to use a different port to avoid conflicts:

```bash
PORT=4143 bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
```

Then point the client to:

```bash
export ANTHROPIC_BASE_URL=http://localhost:4143
```

## 7) Validation recommendation

Never finish without this minimum check:

```bash
curl -I http://localhost:4141/usage
claude -p 'Responde solo con OK'
```
