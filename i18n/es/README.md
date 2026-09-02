# Claude local con Copilot

Este proyecto documenta la configuración local utilizada para ejecutar Claude Code a través de un proxy compatible con GitHub Copilot basado en `copilot-api`, sin depender directamente de la API pública de Anthropic.

## Referencia

- Guía original: https://dev.to/allentcm/using-claude-code-with-github-copilot-subscription-2obj

## Objetivo

El objetivo es mantener un flujo local, controlado y reproducible en el que:

1. `copilot-api` expone un endpoint local compatible con OpenAI/Anthropic.
2. `claude` apunta a ese endpoint local.
3. El proxy traduce la solicitud hacia GitHub Copilot.
4. El cliente usa variables de entorno locales como `ANTHROPIC_BASE_URL` y un token ficticio para pruebas locales.

Esto permite que Claude Code se comporte como un cliente de Anthropic, mientras la ejecución real ocurre a través de Copilot.

## Arquitectura mínima

```text
Claude Code
   │
   ├── env: ANTHROPIC_BASE_URL=http://localhost:4141
   ├── env: ANTHROPIC_AUTH_TOKEN=sk-dummy
   ├── env: ANTHROPIC_MODEL=claude-sonnet-5
   │
   ▼
Proxy local (copilot-api)
   │
   ├── expone /v1/chat/completions, /messages, /usage
   │
   ▼
GitHub Copilot
   │
   └── devuelve la respuesta real
```

## Entorno validado

Estas variables se usaron durante la validación en vivo:

```bash
export ANTHROPIC_BASE_URL=http://localhost:4143
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export ANTHROPIC_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_SONNET_MODEL=claude-sonnet-5
export ANTHROPIC_DEFAULT_HAIKU_MODEL=claude-haiku-4.5
export ANTHROPIC_SMALL_FAST_MODEL=claude-haiku-4.5
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

Para Aider o clientes compatibles con OpenAI:

```bash
export OPENAI_API_BASE=http://localhost:4141/v1
export OPENAI_API_KEY=sk-1234
```

## Qué había que vigilar con cuidado

Durante la configuración aparecieron varios puntos críticos:

- los puertos viejos o los procesos zombie pueden ocultar el fallo real
- las exportaciones antiguas de shell pueden seguir apuntando a la URL incorrecta
- `claude` rechaza conversaciones que terminan con un turno de `assistant`
- que Aider funcione no prueba que Claude funcione sin una comprobación directa real

## Iniciar el proxy

La ruta más simple es ejecutar el lanzador del proyecto:

```bash
bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
```

El script:

- valida que `copilot-api` exista en PATH
- limpia listeners antiguos en el puerto objetivo
- inicia el proxy con `copilot-api start -p 4141`
- espera a que responda el endpoint `/usage`
- deja el servicio local listo para Claude o Aider

## Comprobación de salud

Antes de asumir que funciona, valida siempre:

```bash
curl -sS http://localhost:4141/usage
```

Si devuelve JSON, el proxy está vivo.

## Validación real recomendada

Esta es la comprobación mínima de extremo a extremo:

```bash
export ANTHROPIC_BASE_URL=http://localhost:4141
export ANTHROPIC_AUTH_TOKEN=sk-dummy
export ANTHROPIC_MODEL=claude-sonnet-5
claude -p 'Responde solo con OK'
```

Salida esperada:

```text
OK
```

## Índice de documentación del proyecto

- [../../docs/README.md](../../docs/README.md): índice Markdown del proyecto
- [../../docs/quickstart.md](../../docs/quickstart.md): guía rápida de configuración
- [../../docs/troubleshooting.md](../../docs/troubleshooting.md): problemas frecuentes y soluciones
- [../../notes/operational-notes.md](../../notes/operational-notes.md): notas operativas validadas
- [../../i18n/es/README.md](../../i18n/es/README.md): traducción al español de la guía oficial
- [../../env.example](../../env.example): plantilla de entorno local
- [../../scripts/start_proxy.sh](../../scripts/start_proxy.sh): script robusto de inicio

## Reglas para agentes futuros

- nunca asumir que una corrección funciona sin ejecutar un comando real
- validar siempre con `curl` y luego con el cliente real
- revisar puerto, proceso y entorno actual antes de reiniciar a ciegas
- mantener un flujo de inicio único y reproducible

## Nota final

Esta configuración local existe para mantener Claude Code usable con GitHub Copilot conservando un flujo local, auditable y fácil de reconstruir. El proyecto está documentado de forma intencional para que un agente futuro pueda reconstruir el entorno sin perder el contexto de depuración.
