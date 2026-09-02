# Quickstart

## 1) Levantar el proxy local

```bash
bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
```

El script hace esto automáticamente:

- valida que `copilot-api` está instalado
- mata procesos viejos en el puerto
- inicia `copilot-api start -p 4141`
- espera a que `/usage` responda

## 2) Verificar que el proxy está vivo

```bash
curl -sS http://localhost:4141/usage
```

Si devuelve JSON, el proxy está operando.

## 3) Exportar variables para Claude

```bash
export ANTHROPIC_BASE_URL=http://localhost:4141
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export ANTHROPIC_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4.5
export ANTHROPIC_SMALL_FAST_MODEL=claude-haiku-4.5
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

## 4) Probar una llamada real

```bash
claude -p 'Responde solo con OK'
```

Salida esperada:

```text
OK
```

## 5) Para Aider o clientes OpenAI-compatible

```bash
export OPENAI_API_BASE=http://localhost:4141/v1
export OPENAI_API_KEY=sk-1234
```

Y luego:

```bash
aider --model openai/claude-sonnet-5
```

## 6) Si se quiere probar en un puerto limpio

A veces conviene usar un puerto distinto para pruebas sin conflicto:

```bash
PORT=4143 bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
```

Y luego apuntar el cliente a:

```bash
export ANTHROPIC_BASE_URL=http://localhost:4143
```

## 7) Recomendación de validación

Nunca finalizar sin este check mínimo:

```bash
curl -I http://localhost:4141/usage
claude -p 'Responde solo con OK'
```
