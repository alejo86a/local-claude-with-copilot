# Operational notes

## Estado verificado

Durante la validación real, estas condiciones fueron comprobadas en esta máquina:

- `copilot-api` responde en `http://localhost:4141/usage`
- `claude -p 'Responde solo con OK'` funciona cuando `ANTHROPIC_BASE_URL` apunta al proxy correcto
- con un puerto limpio, la ruta directa fue validada con `export ANTHROPIC_BASE_URL=http://localhost:4143`

## Pitfalls observados

1. `ANTHROPIC_BASE_URL` viejo en el shell
2. proceso de proxy previo en un puerto ocupado
3. conversación terminando en `assistant`
4. asumir que Aider funciona y Claude también sin probarlo

## Reglas de operación

- `curl` antes de `claude`
- `ps` / `lsof` antes de reiniciar
- un puerto y una terminal a la vez
- prueba real antes de cerrar el problema

## Config válida

```bash
export ANTHROPIC_BASE_URL=http://localhost:4143
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export ANTHROPIC_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4.5
export ANTHROPIC_SMALL_FAST_MODEL=claude-haiku-4.5
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

## Recomendación

Cuando vuelvas a levantar el entorno, usa el script `scripts/start_proxy.sh` y valida con `curl` + `claude -p 'Responde solo con OK'` antes de seguir con trabajo creativo o de integración.
