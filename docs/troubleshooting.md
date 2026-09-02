# Troubleshooting

## 1) El proxy no responde

Revisar primero el puerto y el proceso:

```bash
lsof -nP -iTCP:4141 -sTCP:LISTEN || true
ps -ef | grep copilot-api | grep -v grep || true
curl -I http://localhost:4141/usage
```

Si hay un proceso viejo o el puerto está ocupado:

```bash
pkill -f 'copilot-api' || true
bash /Users/alejo86a/code/personal/local-claude-with-copilot/scripts/start_proxy.sh
```

## 2) Connection refused

Esto normalmente significa que el proxy no está levantado o que la terminal tiene un env viejo.

Revisar:

```bash
echo $ANTHROPIC_BASE_URL
curl -I http://localhost:4141/usage
```

Si no responde, reiniciar el proxy.

## 3) Variables de entorno viejas

Un error muy común es que una terminal ya exportó la URL incorrecta y sigue usando esa configuración aunque el proxy nuevo funcione.

Solución:

```bash
unset ANTHROPIC_BASE_URL
export ANTHROPIC_BASE_URL=http://localhost:4141
```

O abrir una terminal nueva y re-exportar todo.

## 4) El cliente falla aunque el proxy sí responde

Hay que distinguir dos cosas:

- el proxy está vivo
- el cliente está apuntando al puerto correcto

Comprueba tanto con `curl` como con el comando real del cliente:

```bash
curl -sS http://localhost:4141/usage
claude -p 'Responde solo con OK'
```

## 5) Error de conversación final con `assistant`

Este es un caso clásico del cliente Anthropic y se da cuando el historial termina con un turno de `assistant` en vez de `user`.

Regla: la última entrada de la conversación debe ser `user`.

Si aparecen errores del tipo:

```text
This model does not support assistant message prefill. The conversation must end with a user message.
```

entonces hay que limpiar el historial antes de enviar la petición, o usar una nueva conversación sin contenido previo.

## 6) Modelo no reconocido o no se encuentra disponible

Verifica qué modelo está activo en el entorno:

```bash
echo $ANTHROPIC_MODEL
```

Y usa uno que esté disponible en la lista del backend. En este entorno el modelo validado fue:

```bash
claude-sonnet-5
```

## 7) Que no se declare éxito sin prueba real

La regla más importante del proyecto es esta:

- no basta con ver el archivo de config
- no basta con suponer que el proxy está bien
- hay que ejecutar una prueba real con `claude` o `aider`

Comando mínimo de validación:

```bash
claude -p 'Responde solo con OK'
```

Si no devuelve `OK`, no se considera resuelto.
