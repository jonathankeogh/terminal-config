#!/bin/bash
# PreInvocation hook for Antigravity: inject Europe/Dublin local date/time once
# per user turn (invocationNum == 1 so multi-tool turns don't repeat it).
exec python3 -c '
import json, sys
from datetime import datetime
from zoneinfo import ZoneInfo

try:
    payload = json.load(sys.stdin)
except Exception:
    print("{}")
    sys.exit(0)

if payload.get("invocationNum", 1) != 1:
    print("{}")
    sys.exit(0)

now = datetime.now(ZoneInfo("Europe/Dublin")).strftime("%Y-%m-%d %H:%M:%S %Z (%A)")
print(json.dumps({
    "injectSteps": [{
        "systemMessage": {
            "systemMessage": f"Current date/time in Europe/Dublin when the user sent this message: {now}"
        }
    }]
}))
'
