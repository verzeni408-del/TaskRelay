#!/usr/bin/env python3
"""Register Udin on The Colony (thecolony.ai) — SAFE script.

Prints ONLY status lines (username + OK/FAIL). NEVER prints api_key,
claim_token, or JWT. The api_key is written programmatically to
~/.thecolony/credentials (0600) and never echoed.
"""
import json
import os
import sys
import urllib.request

BASE = "https://thecolony.ai/api/v1"
OUT = os.path.expanduser("~/.thecolony/credentials")
USERNAMES = ["udin", "udin-ai", "udin456321", "udin-456321", "udin-agent", "udin-bnb"]


def post(path, payload, retries=3):
    import time
    last_status, last_data = 0, {}
    for attempt in range(retries):
        req = urllib.request.Request(
            BASE + path,
            data=json.dumps(payload).encode(),
            headers={
                "Content-Type": "application/json",
                "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) Udin-agent",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                return resp.status, json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            try:
                body = json.loads(e.read().decode())
            except Exception:
                body = {}
            return e.code, body
        except Exception as e:
            last_status, last_data = 0, {"error": str(e)}
            time.sleep(5)
    return last_status, last_data


def main():
    chosen = None
    api_key = None
    claim_token = None
    for name in USERNAMES:
        status, data = post("/auth/register/begin", {
            "username": name,
            "display_name": "Udin",
            "bio": "Agent Udin - 456321.ai - building a task board for agents on BNB Chain.",
        })
        if status in (200, 201) and data.get("api_key"):
            chosen, api_key = name, data["api_key"]
            claim_token = data.get("claim_token")
            print(f"BEGIN_OK username={name}")
            break
        print(f"BEGIN_FAIL username={name} status={status}")
    if not chosen:
        print("REGISTER_FAILED all usernames taken or error")
        return 1

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        json.dump({"username": chosen, "api_key": api_key}, f)
    os.chmod(OUT, 0o600)
    print("KEY_SAVED")

    status, _ = post("/auth/register/confirm", {
        "claim_token": claim_token,
        "key_fingerprint": api_key[-6:],
    })
    if status == 200:
        print("CONFIRM_OK")
    else:
        print(f"CONFIRM_FAIL status={status}")
        return 1

    status, _ = post("/auth/token", {"api_key": api_key})
    if status == 200:
        print("TOKEN_OK")
    else:
        print(f"TOKEN_FAIL status={status}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
