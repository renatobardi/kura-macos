#!/usr/bin/env python3
"""
Hook #3 — Swift Keychain Enforcer (PreToolUse: Write | Edit)
kura-macos

Bloqueia o armazenamento de tokens, credenciais e dados sensíveis
em UserDefaults. Dados sensíveis DEVEM ir para o Keychain via
Security framework (SecItemAdd / SecItemCopyMatching).

Exit com JSON deny → bloqueia a ação e mostra motivo ao Claude.
"""
import json
import re
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

tool_name  = data.get("tool_name", "")
tool_input = data.get("tool_input", {})

if tool_name not in ("Write", "Edit"):
    sys.exit(0)

file_path = tool_input.get("file_path", "")
if not file_path.endswith(".swift"):
    sys.exit(0)

content = tool_input.get("content", "") or tool_input.get("new_string", "")
if not content:
    sys.exit(0)

# Chaves que indicam dados sensíveis
SENSITIVE_KEYS = [
    "token", "key", "secret", "auth", "credential",
    "password", "apikey", "api_key", "accesstoken",
    "refreshtoken", "idtoken", "bearer",
]

# Padrões UserDefaults com chave sensível
PATTERNS = [
    r'UserDefaults\.standard\.set\s*\([^,\n]+,\s*forKey\s*:\s*["\']([^"\']+)["\']',
    r'UserDefaults\.standard\.setValue\s*\([^,\n]+,\s*forKey\s*:\s*["\']([^"\']+)["\']',
    r'defaults\.set\s*\([^,\n]+,\s*forKey\s*:\s*["\']([^"\']+)["\']',
    r'defaults\.setValue\s*\([^,\n]+,\s*forKey\s*:\s*["\']([^"\']+)["\']',
]

lines   = content.split("\n")
found   = []

for i, line in enumerate(lines, 1):
    for pattern in PATTERNS:
        match = re.search(pattern, line, re.IGNORECASE)
        if match:
            key = match.group(1).lower()
            if any(sensitive in key for sensitive in SENSITIVE_KEYS):
                found.append(f"  Linha {i}: {line.strip()}")

if found:
    violations = "\n".join(found)
    reason = (
        f"SWIFT KEYCHAIN ENFORCER bloqueou escrita em '{file_path}'.\n\n"
        f"Dados sensíveis detectados em UserDefaults:\n{violations}\n\n"
        f"Tokens, credenciais e API keys DEVEM ser armazenados no Keychain "
        f"via Security framework (SecItemAdd / SecItemCopyMatching).\n\n"
        f"Nunca use UserDefaults para dados sensíveis — "
        f"são persistidos em plain text no disco."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }))

sys.exit(0)
