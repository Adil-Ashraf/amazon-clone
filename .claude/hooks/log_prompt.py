#!/usr/bin/env python3
import json, sys, datetime, pathlib

data = json.load(sys.stdin)
session_id = data.get("session_id", "unknown-session")
prompt = data.get("prompt", "")
ts = datetime.datetime.utcnow().isoformat() + "Z"

state_dir = pathlib.Path(".agent-logs/.state")
state_dir.mkdir(parents=True, exist_ok=True)
state_file = state_dir / f"{session_id}.json"

state = json.loads(state_file.read_text()) if state_file.exists() else {
    "session_id": session_id, "count": 0, "log_file": None, "first_prompt_time": ts
}
state["count"] += 1
state["pending_prompt"] = prompt
state["pending_prompt_time"] = ts
state["last_prompt_time"] = ts
state_file.write_text(json.dumps(state))
