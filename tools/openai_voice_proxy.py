#!/usr/bin/env python3
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


HOST = os.getenv("VOICE_PROXY_HOST", "0.0.0.0")
PORT = int(os.getenv("VOICE_PROXY_PORT", "8787"))
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip()
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-5.4-mini").strip()
VOICE_PROXY_TOKEN = os.getenv("VOICE_PROXY_TOKEN", "").strip()


TASK_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "title": {"type": "string"},
        "project_hint": {"anyOf": [{"type": "string"}, {"type": "null"}]},
        "matched_project_name": {
            "anyOf": [{"type": "string"}, {"type": "null"}],
        },
        "due_at": {
            "type": "string",
            "description": "ISO 8601 local datetime without timezone offset.",
        },
        "due_date_was_inferred": {"type": "boolean"},
        "due_time_was_inferred": {"type": "boolean"},
        "notes": {"type": "array", "items": {"type": "string"}},
    },
    "required": [
        "title",
        "project_hint",
        "matched_project_name",
        "due_at",
        "due_date_was_inferred",
        "due_time_was_inferred",
        "notes",
    ],
}


SCHEDULE_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "title": {"type": "string"},
        "location": {"type": "string"},
        "first_start": {
            "type": "string",
            "description": "ISO 8601 local datetime without timezone offset.",
        },
        "first_end": {
            "type": "string",
            "description": "ISO 8601 local datetime without timezone offset.",
        },
        "week_days": {
            "type": "array",
            "items": {"type": "integer"},
        },
        "recurrence_end_date": {
            "anyOf": [
                {
                    "type": "string",
                    "description": "YYYY-MM-DD or ISO 8601 date-time.",
                },
                {"type": "null"},
            ],
        },
        "notes": {"type": "array", "items": {"type": "string"}},
    },
    "required": [
        "title",
        "location",
        "first_start",
        "first_end",
        "week_days",
        "recurrence_end_date",
        "notes",
    ],
}


def _task_system_prompt():
    return (
        "Eres un parser de voz para una app universitaria llamada UniThrive. "
        "Recibirás JSON con transcript, reference_time y contexto. "
        "Devuelve JSON estricto que siga el schema.\n"
        "Reglas:\n"
        "- El idioma del transcript será español.\n"
        "- `matched_project_name` debe ser exactamente uno de los nombres de "
        "   `active_project_names` si el curso coincide de forma clara.\n"
        "- Si no hay coincidencia clara, usa `matched_project_name = null` y "
        "   coloca el mejor curso inferido en `project_hint`.\n"
        "- `due_at` debe ser una fecha local coherente en formato ISO 8601 sin "
        "   zona horaria.\n"
        "- Si no hay fecha clara, usa mañana a las 18:00 y marca "
        "   `due_date_was_inferred = true`.\n"
        "- Si hay fecha pero no hora clara, usa 18:00 y marca "
        "   `due_time_was_inferred = true`.\n"
        "- `notes` debe ser una lista corta en español con aclaraciones útiles.\n"
        "- No inventes proyectos existentes que no aparezcan en el contexto.\n"
        "- Responde solo con JSON válido según el schema."
    )


def _schedule_system_prompt():
    return (
        "Eres un parser de voz para una app universitaria llamada UniThrive. "
        "Recibirás JSON con transcript y reference_time. "
        "Devuelve JSON estricto que siga el schema.\n"
        "Reglas:\n"
        "- El idioma del transcript será español.\n"
        "- `week_days` usa 1=lunes ... 7=domingo.\n"
        "- `first_start` y `first_end` deben ser la primera ocurrencia local "
        "   coherente en o después de `reference_time`, en ISO 8601 sin zona.\n"
        "- Si faltan días, usa el día de `reference_time` y añade una nota.\n"
        "- Si falta horario, usa 09:00 a 11:00 y añade una nota.\n"
        "- Si falta ubicación, usa cadena vacía.\n"
        "- `recurrence_end_date` debe ser YYYY-MM-DD cuando exista una fecha "
        "   de fin clara; si no, null.\n"
        "- `notes` debe ser una lista corta en español con aclaraciones útiles.\n"
        "- Responde solo con JSON válido según el schema."
    )


class ProxyError(Exception):
    pass


def _json_schema(name, schema):
    return {
        "type": "json_schema",
        "name": name,
        "strict": True,
        "schema": schema,
    }


def _call_openai(payload):
    body = json.dumps(payload).encode("utf-8")
    request = Request(
        "https://api.openai.com/v1/responses",
        data=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {OPENAI_API_KEY}",
        },
        method="POST",
    )

    try:
        with urlopen(request, timeout=45) as response:
            raw = response.read().decode("utf-8")
            return json.loads(raw)
    except HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            decoded = json.loads(raw)
            message = decoded.get("error", {}).get("message")
            if message:
                raise ProxyError(f"OpenAI devolvió un error: {message}")
        except json.JSONDecodeError:
            pass
        raise ProxyError(f"OpenAI devolvió HTTP {exc.code}.")
    except URLError as exc:
        raise ProxyError(f"No se pudo contactar a OpenAI: {exc.reason}")


def _extract_output_text(response_json):
    output_text = response_json.get("output_text")
    if isinstance(output_text, str) and output_text.strip():
        return output_text

    fragments = []
    for item in response_json.get("output", []):
        if item.get("type") != "message":
            continue
        for content in item.get("content", []):
            refusal = content.get("refusal")
            if refusal:
                raise ProxyError(f"El modelo rechazó la solicitud: {refusal}")

            content_type = content.get("type")
            if content_type in {"output_text", "text"}:
                text = content.get("text")
                if isinstance(text, str) and text.strip():
                    fragments.append(text)

    if fragments:
        return "".join(fragments)

    raise ProxyError("OpenAI no devolvió texto estructurado utilizable.")


def _build_openai_payload(kind, client_payload):
    if kind == "task":
        return {
            "model": OPENAI_MODEL,
            "input": [
                {"role": "system", "content": _task_system_prompt()},
                {
                    "role": "user",
                    "content": json.dumps(client_payload, ensure_ascii=False),
                },
            ],
            "text": {"format": _json_schema("voice_task_parse", TASK_SCHEMA)},
        }

    if kind == "schedule":
        return {
            "model": OPENAI_MODEL,
            "input": [
                {"role": "system", "content": _schedule_system_prompt()},
                {
                    "role": "user",
                    "content": json.dumps(client_payload, ensure_ascii=False),
                },
            ],
            "text": {
                "format": _json_schema("voice_schedule_parse", SCHEDULE_SCHEMA),
            },
        }

    raise ProxyError("Tipo de parse no soportado.")


class VoiceProxyHandler(BaseHTTPRequestHandler):
    server_version = "UniThriveVoiceProxy/1.0"

    def do_OPTIONS(self):
        self.send_response(204)
        self._write_common_headers()
        self.end_headers()

    def do_POST(self):
        if self.path != "/parse":
            self._send_json(404, {"error": "Ruta no encontrada."})
            return

        if VOICE_PROXY_TOKEN:
            authorization = self.headers.get("Authorization", "")
            expected = f"Bearer {VOICE_PROXY_TOKEN}"
            if authorization != expected:
                self._send_json(401, {"error": "Token del proxy inválido."})
                return

        try:
            body = self._read_json_body()
            kind = body.get("kind")
            transcript = str(body.get("transcript", "")).strip()
            if kind not in {"task", "schedule"}:
                raise ProxyError("`kind` debe ser `task` o `schedule`.")
            if not transcript:
                raise ProxyError("`transcript` es obligatorio.")

            openai_payload = _build_openai_payload(kind, body)
            openai_response = _call_openai(openai_payload)
            output_text = _extract_output_text(openai_response)
            parsed = json.loads(output_text)
            if not isinstance(parsed, dict):
                raise ProxyError("La respuesta estructurada no fue un objeto.")

            self._send_json(200, {"kind": kind, "result": parsed})
        except ProxyError as exc:
            self._send_json(422, {"error": str(exc)})
        except json.JSONDecodeError:
            self._send_json(400, {"error": "El body no es JSON válido."})
        except Exception as exc:
            self._send_json(500, {"error": f"Error interno del proxy: {exc}"})

    def _read_json_body(self):
        content_length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(content_length)
        return json.loads(raw.decode("utf-8"))

    def _write_common_headers(self):
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header(
            "Access-Control-Allow-Headers",
            "Content-Type, Authorization",
        )
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")

    def _send_json(self, status_code, payload):
        encoded = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status_code)
        self._write_common_headers()
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def log_message(self, format_string, *args):
        sys.stdout.write(
            "%s - - [%s] %s\n"
            % (
                self.address_string(),
                self.log_date_time_string(),
                format_string % args,
            )
        )


def main():
    if not OPENAI_API_KEY:
        print("Falta OPENAI_API_KEY.", file=sys.stderr)
        sys.exit(1)

    server = ThreadingHTTPServer((HOST, PORT), VoiceProxyHandler)
    print(
        f"UniThrive voice proxy escuchando en http://{HOST}:{PORT}/parse "
        f"con modelo {OPENAI_MODEL}"
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nCerrando proxy...")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
