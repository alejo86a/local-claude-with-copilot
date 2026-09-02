# Quickstart

## 1) Start the local proxy

```bash
bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
```

The script does this automatically:

- checks that `copilot-api` is installed
- kills stale processes on the port
- starts `copilot-api start -p 4141`
- waits for `/usage` to respond

## 2) Verify that the proxy is alive

```bash
curl -sS http://localhost:4141/usage
```

If it returns JSON, the proxy is running.

## 3) Export Claude environment variables

```bash
export ANTHROPIC_BASE_URL=http://localhost:4141
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export ANTHROPIC_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4.5
export ANTHROPIC_SMALL_FAST_MODEL=claude-haiku-4.5
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

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
