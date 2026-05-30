#!/usr/bin/env python3
"""
Hook #7 — Swift Commit Gate (PreToolUse: Bash)
kura-macos

Bloqueia git commit se xcodebuild test falhar.
Pula graciosamente durante o bootstrap (antes do projeto Xcode existir).

Exit com JSON deny → bloqueia o commit e mostra erros ao Claude.
"""
import json
import os
import re
import subprocess
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

if data.get("tool_name") != "Bash":
    sys.exit(0)

command = data.get("tool_input", {}).get("command", "")

if not re.search(r"\bgit\s+commit\b", command):
    sys.exit(0)

# Encontra root do repositório
try:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True, text=True, check=True
    )
    repo_root = result.stdout.strip()
except subprocess.CalledProcessError:
    sys.exit(0)

# Bootstrap phase: pula se o projeto Xcode ainda não existe
xcodeproj = next(
    (f for f in os.listdir(repo_root) if f.endswith(".xcodeproj")),
    None
)
if not xcodeproj:
    sys.exit(0)

scheme = os.path.splitext(xcodeproj)[0]

print(json.dumps({
    "additionalContext": f"SWIFT COMMIT GATE: Rodando xcodebuild test -scheme {scheme}..."
}), flush=True)

result = subprocess.run(
    [
        "xcodebuild", "test",
        "-scheme", scheme,
        "-destination", "platform=macOS",
        "-quiet",
    ],
    cwd=repo_root,
    capture_output=True,
    text=True,
)

if result.returncode != 0:
    output = (result.stdout + result.stderr).strip()
    last_lines = "\n".join(output.split("\n")[-40:]) if output else "(sem output)"
    reason = (
        f"SWIFT COMMIT GATE: xcodebuild test falhou — commit bloqueado.\n\n"
        f"Corrija os testes antes de commitar.\n\n"
        f"{last_lines}"
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))

sys.exit(0)
