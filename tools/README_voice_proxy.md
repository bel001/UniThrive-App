# UniThrive Voice Proxy

Este proxy permite que `UniThrive-App` mejore el parser local de voz usando OpenAI sin guardar una API key dentro de Flutter.

## Qué hace

- Recibe el transcript ya capturado por la app.
- Lo envía a la Responses API con Structured Outputs.
- Devuelve JSON estricto para:
  - crear tareas por voz
  - crear horarios/clases por voz

## Requisitos

- Python 3.10+
- `OPENAI_API_KEY`

No necesita dependencias externas de Python.

## Arranque rápido

```bash
cd UniThrive-App
export OPENAI_API_KEY="tu_api_key"
export OPENAI_MODEL="gpt-5.4-mini"
export VOICE_PROXY_TOKEN="token-opcional-del-proxy"
python3 tools/openai_voice_proxy.py
```

Por defecto escucha en `http://0.0.0.0:8787/parse`.

Variables opcionales:

- `VOICE_PROXY_HOST`
- `VOICE_PROXY_PORT`
- `VOICE_PROXY_TOKEN`
- `OPENAI_MODEL`

## Cómo conectarlo desde la app

En `Ajustes > Voz e IA`:

1. Abre `Endpoint IA seguro`.
2. Coloca la URL del proxy.
3. Si configuraste `VOICE_PROXY_TOKEN`, pega ese token en el campo opcional.
4. Activa `Mejorar dictado con IA`.

URLs típicas:

- Emulador Android: `http://10.0.2.2:8787/parse`
- Linux/Web local: `http://127.0.0.1:8787/parse`
- Teléfono físico en tu red: `http://TU-IP-LOCAL:8787/parse`

## Seguridad

- La API key real de OpenAI vive solo en el proxy.
- La app guarda únicamente la URL y un token opcional del proxy.
- Para producción, usa HTTPS y considera volver a desactivar `usesCleartextTraffic` en Android.

## Comportamiento en la app

- Si el proxy responde bien, el borrador por voz se refina antes de guardar.
- Si el proxy falla, expira o no está configurado, la app sigue usando el parser local.
