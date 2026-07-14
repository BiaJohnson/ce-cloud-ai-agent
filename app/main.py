"""HTTP API + Gemini tool-calling loop (Vertex AI)."""

from __future__ import annotations

import json
import os
from typing import Any

from flask import Flask, jsonify, request
from google import genai
from google.genai import types

from app.tools import TOOL_FUNCTIONS

app = Flask(__name__)

PROJECT = os.environ["GCP_PROJECT"]
REGION = os.environ.get("REGION", "us-central1")
MODEL = os.environ.get("MODEL", "gemini-2.5-flash")

client = genai.Client(vertexai=True, project=PROJECT, location=REGION)

SYSTEM = (
    "You are an internal ops assistant. "
    "Use tools when needed. Only use the provided read-only tools. "
    "Never invent delete/update actions. Keep answers short and practical."
)

TOOLS = types.Tool(
    function_declarations=[
        types.FunctionDeclaration(
            name="list_cloud_run_services",
            description="List Cloud Run services in a project/region (names and URIs).",
            parameters=types.Schema(
                type=types.Type.OBJECT,
                properties={
                    "project": types.Schema(type=types.Type.STRING),
                    "region": types.Schema(type=types.Type.STRING),
                },
            ),
        ),
        types.FunctionDeclaration(
            name="recent_error_logs",
            description="Fetch recent ERROR-level Cloud Logging entries (truncated).",
            parameters=types.Schema(
                type=types.Type.OBJECT,
                properties={
                    "project": types.Schema(type=types.Type.STRING),
                    "filter": types.Schema(type=types.Type.STRING),
                    "limit": types.Schema(type=types.Type.INTEGER),
                },
            ),
        ),
    ]
)


def run_tool(name: str, args: dict[str, Any]) -> dict[str, Any]:
    fn = TOOL_FUNCTIONS.get(name)
    if not fn:
        return {"error": f"tool not allowed: {name}"}
    return fn(**(args or {}))


def chat_once(user_message: str) -> dict[str, Any]:
    """Simple loop: ask Gemini → maybe tools → final text. Max a few rounds."""
    contents: list[types.Content] = [
        types.Content(role="user", parts=[types.Part(text=user_message)]),
    ]
    tool_trace: list[dict[str, Any]] = []

    for _ in range(3):
        response = client.models.generate_content(
            model=MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                system_instruction=SYSTEM,
                tools=[TOOLS],
                temperature=0.2,
            ),
        )

        candidate = response.candidates[0]
        parts = candidate.content.parts or []

        function_calls = [p.function_call for p in parts if p.function_call]
        if not function_calls:
            text = "".join(p.text or "" for p in parts)
            return {"reply": text, "tools_used": tool_trace}

        # Append model turn, then tool results
        contents.append(candidate.content)
        tool_parts = []
        for fc in function_calls:
            args = dict(fc.args or {})
            result = run_tool(fc.name, args)
            tool_trace.append({"name": fc.name, "args": args, "result": result})
            tool_parts.append(
                types.Part.from_function_response(
                    name=fc.name,
                    response={"result": result},
                )
            )
        contents.append(types.Content(role="user", parts=tool_parts))

    return {"reply": "Stopped after max tool rounds.", "tools_used": tool_trace}


@app.get("/health")
def health():
    return "ok", 200


@app.post("/chat")
def chat():
    body = request.get_json(silent=True) or {}
    message = (body.get("message") or "").strip()
    if not message:
        return jsonify({"error": "message is required"}), 400
    try:
        result = chat_once(message)
        return jsonify(result)
    except Exception as exc:  # noqa: BLE001 — PoC: surface errors clearly
        return jsonify({"error": str(exc)}), 500


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    app.run(host="0.0.0.0", port=port, debug=True)