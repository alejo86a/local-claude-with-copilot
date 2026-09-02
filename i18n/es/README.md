# Claude local con Copilot

Referencia en español para la configuración local de Claude + GitHub Copilot. Esta es una traducción de soporte y no la versión principal del repositorio.

> Nota: no existe una versión en español de [../../docs/quickstart.md](../../docs/quickstart.md). El quickstart canónico permanece en inglés. Esta carpeta solo ofrece una referencia de apoyo.

## Qué contiene este proyecto

- notas de configuración del proxy local
- plantilla de variables de entorno para Claude y Aider
- script de arranque para `copilot-api`
- documentación de troubleshooting para errores comunes
- notas operativas validadas para futuros agentes

## Documentos relacionados

- [../../README.md](../../README.md)
- [../../docs/README.md](../../docs/README.md)
- [../../docs/quickstart.md](../../docs/quickstart.md)
- [../../docs/troubleshooting.md](../../docs/troubleshooting.md)
- [../../notes/operational-notes.md](../../notes/operational-notes.md)
- [../../scripts/start_proxy.sh](../../scripts/start_proxy.sh)
- [../../env.example](../../env.example)

## Resumen rápido

Este proyecto permite mantener Claude Code funcionando a través de un proxy local basado en `copilot-api`. El cliente apunta a un endpoint compatible con Anthropic, y el proxy reenvía la petición a GitHub Copilot. Así se conserva un flujo local reproducible y verificable para desarrollo y soporte futuro.
