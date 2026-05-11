#!/usr/bin/env python3
"""
MCP stdio <-> HTTP proxy for the rudder-scenario-engine.

Claude Code spawns this script via .mcp.json (type: stdio).

Design:
  - Handshake (`initialize`, `notifications/initialized`, `tools/list`) is
    answered IMMEDIATELY by the proxy. Cached tool list survives across
    sessions in /tmp/rudder-mcp-tools.json so the very first session is fast too.
  - The XCTest gateway boots in a background thread. Real `tools/call`
    requests block until it's ready (up to BOOT_TIMEOUT), then are proxied
    to the MCPServer HTTP endpoint.
  - Port is dynamic per gateway run, cached in /tmp/rudder-mcp.port so
    subsequent sessions reuse the still-alive gateway instantly.
"""

import sys
import json
import subprocess
import socket
import time
import http.client
import os
import threading
from typing import Optional, Tuple, Any, Dict

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PORT_FILE = "/tmp/rudder-mcp.port"
TOOLS_CACHE = "/tmp/rudder-mcp-tools.json"
TOOLS_MANIFEST = os.path.join(SCRIPT_DIR, "rudder_mcp_tools.json")
GATEWAY_LOG = "/tmp/rudder-mcp-gateway.log"
BOOT_TIMEOUT = 600
PROTOCOL_VERSION = "2024-11-05"


# ---------- logging ----------

def _log(msg: str) -> None:
    sys.stderr.write(f"[rudder-mcp] {msg}\n")
    sys.stderr.flush()


# ---------- port + simulator helpers ----------

def _find_free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("", 0))
        return s.getsockname()[1]


def _load_port() -> Optional[int]:
    try:
        return int(open(PORT_FILE).read().strip())
    except Exception:
        return None


def _save_port(port: int) -> None:
    try:
        open(PORT_FILE, "w").write(str(port))
    except Exception:
        pass


def _is_running(port: int) -> bool:
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=1):
            return True
    except OSError:
        return False


def _pick_simulator() -> str:
    try:
        raw = subprocess.check_output(
            ["xcrun", "simctl", "list", "devices", "available", "--json"],
            stderr=subprocess.DEVNULL,
        )
        data = json.loads(raw)
        booted_name, fallback_name = None, None
        for runtime, devices in data.get("devices", {}).items():
            if "iOS" not in runtime:
                continue
            for d in devices:
                if "iPhone" not in d.get("name", ""):
                    continue
                if d.get("state") == "Booted" and booted_name is None:
                    booted_name = d["name"]
                if fallback_name is None:
                    fallback_name = d["name"]
        name = booted_name or fallback_name
        if name:
            _log(f"Using simulator: {name} ({'booted' if booted_name else 'will boot'})")
            return f"platform=iOS Simulator,name={name}"
    except Exception as exc:
        _log(f"simctl error: {exc}")
    return "generic/platform=iOS Simulator"


# ---------- gateway boot (runs on background thread) ----------

def _spawn_xcodebuild(port: int) -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    project = os.path.join(root, "E2ETests", "RudderSUT", "RudderSUT.xcodeproj")
    destination = _pick_simulator()
    _log(f"Spawning XCTest gateway on port {port} (logs: {GATEWAY_LOG})")
    log_file = open(GATEWAY_LOG, "w")

    # TEST_RUNNER_* env vars are stripped of the prefix by xcodebuild and
    # injected into the test runner's process environment. They MUST be in
    # the shell environment of xcodebuild — passing them as argv after the
    # test command makes them build settings, not env vars.
    env = os.environ.copy()
    env["TEST_RUNNER_MCP_GATEWAY"] = "1"
    env["TEST_RUNNER_MCP_GATEWAY_PORT"] = str(port)
    env["TEST_RUNNER_MCP_GATEWAY_TIMEOUT"] = "86400"  # 24h — survives any reasonable session

    subprocess.Popen(
        [
            "xcodebuild", "test",
            "-project", project,
            "-scheme", "RudderSUT",
            "-destination", destination,
            "-only-testing:RudderUITests/MCPGatewayTest/testMCPGateway",
        ],
        env=env,
        stdout=log_file,
        stderr=log_file,
        start_new_session=True,
    )


def _wait_for_port(port: int) -> bool:
    deadline = time.time() + BOOT_TIMEOUT
    while time.time() < deadline:
        if _is_running(port):
            return True
        time.sleep(2)
    return False


# ---------- HTTP proxy ----------

def _post(payload: str, session_id: Optional[str], port: int) -> Tuple[Optional[str], Optional[str]]:
    conn = None
    try:
        conn = http.client.HTTPConnection("127.0.0.1", port, timeout=120)
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
        }
        if session_id:
            headers["mcp-session-id"] = session_id
        conn.request("POST", "/", payload, headers)
        resp = conn.getresponse()
        new_sid = resp.getheader("mcp-session-id") or session_id
        ctype = resp.getheader("Content-Type", "")
        if "text/event-stream" in ctype:
            lines = []
            for raw in resp.read().decode().splitlines():
                if raw.startswith("data: "):
                    data = raw[6:].strip()
                    if data and data != "[DONE]":
                        lines.append(data)
            return ("\n".join(lines) or None), new_sid
        body = resp.read().decode().strip()
        return (body or None), new_sid
    except Exception as exc:
        _log(f"HTTP error: {exc}")
        return None, session_id
    finally:
        if conn:
            try: conn.close()
            except Exception: pass


# ---------- shared state ----------

class State:
    port: Optional[int] = None
    session_id: Optional[str] = None  # session with the gateway (proxy ↔ gateway)
    ready = threading.Event()
    failed = False
    boot_lock = threading.Lock()

state = State()


def _bootstrap() -> None:
    """Background: start gateway, then perform proxy↔gateway MCP handshake.
    Idempotent — safe to call again to recover from gateway death."""
    with state.boot_lock:
        # Re-check inside the lock in case another thread already booted.
        if state.port and _is_running(state.port):
            if state.ready.is_set() and not state.failed:
                return  # already healthy

        state.ready.clear()
        state.failed = False
        state.session_id = None

        port = _load_port()
        if port and _is_running(port):
            _log(f"Reusing live gateway on port {port}.")
            state.port = port
        else:
            port = _find_free_port()
            _save_port(port)
            state.port = port
            _spawn_xcodebuild(port)
            if not _wait_for_port(port):
                _log(f"Gateway didn't open port {port} within {BOOT_TIMEOUT}s. See {GATEWAY_LOG}.")
                state.failed = True
                state.ready.set()
                return

        init = json.dumps({
            "jsonrpc": "2.0", "id": "proxy-init", "method": "initialize",
            "params": {
                "protocolVersion": PROTOCOL_VERSION,
                "capabilities": {},
                "clientInfo": {"name": "rudder-mcp-proxy", "version": "1.0"},
            },
        })
        resp, sid = _post(init, None, state.port)
        if resp is None:
            _log("Gateway responded but initialize failed.")
            state.failed = True
            state.ready.set()
            return
        state.session_id = sid

        notif = json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"})
        _post(notif, sid, state.port)

        list_req = json.dumps({"jsonrpc": "2.0", "id": "proxy-tools", "method": "tools/list"})
        tools_resp, _ = _post(list_req, sid, state.port)
        if tools_resp:
            try:
                payload = json.loads(tools_resp)
                tools = payload.get("result", {}).get("tools")
                if tools:
                    open(TOOLS_CACHE, "w").write(json.dumps(tools))
            except Exception:
                pass

        _log(f"Gateway ready on port {state.port}.")
        state.ready.set()


def _ensure_healthy() -> bool:
    """Make sure the gateway is alive. Restart if dead. Return True if healthy."""
    if state.port and _is_running(state.port) and state.session_id and not state.failed:
        return True
    _log("Gateway down or never ready — booting.")
    threading.Thread(target=_bootstrap, daemon=True).start()
    state.ready.wait(timeout=BOOT_TIMEOUT)
    return bool(state.port and _is_running(state.port) and not state.failed)


# ---------- handshake responses (sent BEFORE gateway is ready) ----------

def _initialize_response(req_id: Any) -> Dict[str, Any]:
    return {
        "jsonrpc": "2.0", "id": req_id,
        "result": {
            "protocolVersion": PROTOCOL_VERSION,
            "capabilities": {"tools": {"listChanged": False}},
            "serverInfo": {"name": "rudder-scenario-engine", "version": "1.0"},
        },
    }


def _cached_tools() -> Any:
    """Live cache from a previous gateway run, then bundled manifest as fallback."""
    for path in (TOOLS_CACHE, TOOLS_MANIFEST):
        try:
            return json.loads(open(path).read())
        except Exception:
            continue
    return []


def _tools_list_response(req_id: Any) -> Dict[str, Any]:
    return {
        "jsonrpc": "2.0", "id": req_id,
        "result": {"tools": _cached_tools()},
    }


def _error(req_id: Any, message: str) -> Dict[str, Any]:
    return {
        "jsonrpc": "2.0", "id": req_id,
        "error": {"code": -32603, "message": message},
    }


def _write(obj: Dict[str, Any]) -> None:
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


# ---------- main loop ----------

def _forward(line: str, req_id: Any, is_notification: bool) -> None:
    """Forward a request to the gateway, restarting it once if the call fails.
    Always writes a JSON-RPC response (or error) for non-notification requests."""
    if not _ensure_healthy():
        if not is_notification:
            _write(_error(req_id, f"Gateway unavailable. See {GATEWAY_LOG}."))
        return

    resp, _ = _post(line, state.session_id, state.port)

    # If the call failed, the gateway may have died — try one auto-restart.
    if resp is None:
        _log("Forward failed; restarting gateway and retrying once.")
        state.session_id = None
        state.port = None
        if _ensure_healthy():
            resp, _ = _post(line, state.session_id, state.port)

    if is_notification:
        return
    if resp:
        for ln in resp.splitlines():
            if ln.strip():
                sys.stdout.write(ln.strip() + "\n")
                sys.stdout.flush()
    else:
        _write(_error(req_id, f"Tool call failed. See {GATEWAY_LOG}."))


def main() -> None:
    threading.Thread(target=_bootstrap, daemon=True).start()

    for raw in sys.stdin:
        line = raw.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue

        method = msg.get("method", "")
        req_id = msg.get("id")
        is_notification = "id" not in msg

        # Handshake answered locally so Claude Code doesn't wait on cold start.
        if method == "initialize":
            _write(_initialize_response(req_id))
            continue
        if method == "notifications/initialized":
            continue
        if method == "tools/list":
            if state.ready.is_set() and not state.failed and _is_running(state.port or 0):
                resp, _ = _post(line, state.session_id, state.port)
                if resp:
                    for ln in resp.splitlines():
                        if ln.strip():
                            sys.stdout.write(ln.strip() + "\n")
                            sys.stdout.flush()
                    continue
            _write(_tools_list_response(req_id))
            continue

        # Everything else (tools/call, etc.) goes to the gateway with auto-recovery.
        _forward(line, req_id, is_notification)


if __name__ == "__main__":
    main()
