#!/usr/bin/env python3
import json, sys, datetime, pathlib, time

def get_model_from_transcript(transcript_path, retries=5, delay=0.15):
    for attempt in range(retries):
        model = "unknown"
        try:
            lines = open(transcript_path).readlines()
            for line in reversed(lines):
                line = line.strip()
                if not line:
                    continue
                entry = json.loads(line)
                if entry.get("type") == "assistant":
                    msg = entry.get("message", {})
                    if msg.get("model"):
                        model = msg["model"]
                        break
        except Exception as e:
            model = f"error: {e}"
        if model != "unknown" and not model.startswith("error:"):
            return model
        time.sleep(delay)
    return model

data = json.load(sys.stdin)
session_id = data.get("session_id", "unknown-session")
transcript_path = data.get("transcript_path")
response_text = data.get("last_assistant_message", "")

state_file = pathlib.Path(".agent-logs/.state") / f"{session_id}.json"
if not state_file.exists():
    sys.exit(0)

state = json.loads(state_file.read_text())
prompt = state.get("pending_prompt")
if prompt is None:
    sys.exit(0)

model = get_model_from_transcript(transcript_path)
ts = datetime.datetime.utcnow().isoformat() + "Z"
num = state["count"]

logs_dir = pathlib.Path(".agent-logs")
if not state.get("log_file"):
    date_str = datetime.date.today().isoformat()
    state["log_file"] = str(logs_dir / f"{date_str}_{session_id[:8]}.md")

log_path = pathlib.Path(state["log_file"])
is_new = not log_path.exists()

with open(log_path, "a") as f:
    if is_new:
        f.write(f"""---
session_id: {session_id}
date: {datetime.date.today().isoformat()}
model: {model}
tool: claude-code
first_prompt_time: {state.get('first_prompt_time', ts)}
---

# Session Log - {datetime.date.today().isoformat()}

Session: `{session_id}`

---

""")
    f.write(f"""[LOG_ENTRY type=PROMPT num={num} session={session_id}]
timestamp: {state.get('pending_prompt_time', ts)}
model: {model}

{prompt}


[LOG_ENTRY type=RESPONSE num={num} session={session_id}]
timestamp: {ts}
model: {model}

{response_text}

---

""")

state.pop("pending_prompt", None)
state.pop("pending_prompt_time", None)
state_file.write_text(json.dumps(state))
