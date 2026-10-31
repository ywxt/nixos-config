#!/usr/bin/env python3
"""blue-agent — BlueZone asset heartbeat agent.

Unprivileged Linux port of the Windows `blue/agent.ps1` agent
(v0.9.21 — the version the fleet's Windows agents self-update to)
from the BlueZoneAssetManager distribution, rewritten in Python
(stdlib only; loginctl from systemd aside). Same behaviour as the
previous bash port. Key points:

  * Runs as a regular user (invoked by a systemd *user* timer); no
    elevation anywhere. The whole configuration — including the
    GitCode token and the hardcoded asset code / employee id — is
    read from the sops-nix rendered file
    /run/secrets/rendered/blue-agent.json (owner-only), and the 12h
    throttle consults the last timestamp in the remote heartbeat
    array, which the push fetches anyway. Logging goes to stdout →
    the journal *and* the persistent run log
    (XDG_STATE_HOME/blue-agent/run.log, the counterpart of the
    original's log\\run.log), which is uploaded to
    asset_run_log/<asset>_run.log after every heartbeat exactly like
    the original's Push-RunLog.
  * No self-update: the script is built from this repository and
    replaced by `nixos-rebuild`. This replaces the original repo-pull
    + RSA-signature self-update mechanism, which has no equivalent in
    a declarative deployment.
  * No interactive registration: the asset code and employee id are
    declared in secrets/<host>-blue-agent.yaml (sops) and baked into
    the rendered config at activation.
  * The serial-number chain mirrors Get-SerialNumber of the original
    exactly: the `serial` hardcoded in the sops config first (the DMI
    sysfs files are root-only, so the unprivileged agent cannot read
    them directly), then the DMI system serial
    (Win32_ComputerSystemProduct), then the board serial (standing
    in for Win32_BIOS), then the chassis serial
    (Win32_SystemEnclosure), then "GUID-<machine-id>" (the original's
    MachineGuid fallback), else the same literal fallback string.
  * Idle detection uses logind (IdleHint / IdleSinceHint) instead of
    WTSQuerySessionInformation, fixing the original bug where info
    class 4 (WTSSessionId, a small session number) was compared
    against the idle threshold, so the state was always "active".
  * The remote heartbeat file is serialized exactly like the
    original's ConvertTo-Json (Windows PowerShell 5.1): CRLF line
    endings, 4-space indent steps, two spaces after each colon, no
    trailing newline — and a first push writes a bare object, the
    pipeline-unwrap artifact the fleet's Windows agents show in their
    status/ files.
  * When the remote heartbeat file cannot be parsed it is rebuilt as
    a fresh array, fixing the original bug that produced
    `[null, {...}]` entries; a parseable non-array document is
    wrapped like the original's @(...), not dropped.
  * Network handling mirrors the v0.9.21 Push-Heartbeat and
    Get-RemoteFile -NoRetry exactly: 60 retry rounds with one GET
    per round, sha/git-ref conflicts (409/422/400) and 429 rate
    limiting each with their own backoff + jitter (the whole fleet
    shares one GitCode token), and Push-RunLog's 10-round upload
    loop. The v0.9.19 deterministic per-SN task time and the v0.9.9
    random 0-120 s pre-push delay are not ported (the timer keeps a
    fixed schedule + RandomizedDelaySec); StartWhenAvailable
    (v0.9.21) maps to the timer's Persistent=true.
  * Every run.log line matches the original verbatim, down to the
    trailing Exception.Message the original appends after "网络波动",
    "run.log 上传失败" and "执行失败": the .NET WebException text
    Invoke-RestMethod would have raised is reconstructed from the
    HTTP status + the server's reason phrase ("The remote server
    returned an error: (403) Forbidden.") or mapped from the network
    error ("Unable to connect to the remote server", "The operation
    has timed out", "The remote name could not be resolved: '…'"),
    so the uploaded run.log reads exactly like a Windows agent's.
  * HTTP requests carry the original's headers (User-Agent
    "BlueZoneAgent" + Content-Type; no Accept — and, exactly like the
    previous bash port's curl, no Accept-Encoding or Connection
    either; Host and Content-Length are the only headers the transport
    itself adds). `timeout_seconds` from the config is honoured.
  * Large payloads (a grown heartbeat array, the base64 of run.log)
    travel in-process — the bash port needed scratch files to dodge
    the 128KB execve argv limit; Python has no such limit, exactly
    like the original's in-process hashtable.
  * The startup line logs the run identity like the original, but
    the Windows privilege audit (SYSTEM vs elevated) is dropped —
    running unprivileged is the design here.

Usage: blue-agent [run [--force] | status | help]
"""

import base64
import http.client
import json
import os
import pwd
import random
import re
import socket
import ssl
import subprocess
import sys
import time
import urllib.parse
from datetime import datetime, timezone
from pathlib import Path

AGENT_NAME = "blue-agent"
# Mirrors $AgentVersion of the original, so the uploaded run.log is
# indistinguishable from a fleet Windows agent's.
AGENT_VERSION = "0.9.21"
# Get-ApiHeaders of the original, verbatim.
AGENT_UA = "BlueZoneAgent"

# Persistent run log (the original's log\run.log — see init_run_log);
# empty when there is nowhere to keep it, in which case logging goes
# to stdout only, like the original with both log targets unwritable.
RUN_LOG = ""
# Failure reason of the last push_heartbeat; the caller logs it after
# "执行失败: " the way the original's main catch unwraps the exception.
HEARTBEAT_ERROR = ""

# ----------------------------------------------------------------- config --

# Config resolution: explicit override, sops-nix rendered template
# (keep in sync with modules/blue-agent.nix), /etc fallback.
if os.environ.get("BLUE_AGENT_CONFIG"):
    CONFIG_FILE = os.environ["BLUE_AGENT_CONFIG"]
elif os.access("/run/secrets/rendered/blue-agent.json", os.R_OK):
    CONFIG_FILE = "/run/secrets/rendered/blue-agent.json"
else:
    CONFIG_FILE = "/etc/blue-agent/config.json"

API_ENDPOINT = ""
OWNER = ""
REPO = ""
REMOTE_PATH_TEMPLATE = ""
CONFIG_TOKEN = ""
CONFIG_TOKEN_FILE = ""
PUSH_INTERVAL_HOURS = 12
IDLE_THRESHOLD_MS = 600000
TIMEOUT_SECONDS = 60
ASSET = ""
EMPLOYEE = ""
SERIAL = ""


def load_config():
    """Read the rendered config; missing values fall back to the
    defaults the original's Repair-Config / Assert-Config would use."""
    global API_ENDPOINT, OWNER, REPO, REMOTE_PATH_TEMPLATE
    global CONFIG_TOKEN, CONFIG_TOKEN_FILE
    global PUSH_INTERVAL_HOURS, IDLE_THRESHOLD_MS, TIMEOUT_SECONDS
    global ASSET, EMPLOYEE, SERIAL

    try:
        with open(CONFIG_FILE, encoding="utf-8-sig") as f:
            raw = f.read()
    except OSError:
        log(f"config not found or unreadable: {CONFIG_FILE} (set BLUE_AGENT_CONFIG to override)", "ERROR")
        sys.exit(1)
    try:
        doc = json.loads(raw)
    except ValueError as e:
        log(f"config 解析失败: {CONFIG_FILE} ({e}) (set BLUE_AGENT_CONFIG to override)", "ERROR")
        sys.exit(1)
    if not isinstance(doc, dict):
        doc = {}
    gc = doc.get("gitcode")
    if not isinstance(gc, dict):
        gc = {}

    def text(key, default=""):
        # jq's `// empty`: null / false / missing → the default.
        v = gc.get(key)
        if v is None or v is False:
            return default
        return str(v)

    API_ENDPOINT = text("api_endpoint", "https://api.gitcode.com/api/v5")
    # Get-ApiUri: $base.TrimEnd('/')
    API_ENDPOINT = API_ENDPOINT.rstrip("/")
    OWNER = text("owner", "SoftwareEngineering")
    REPO = text("repo", "BlueZoneAssetManager")
    REMOTE_PATH_TEMPLATE = text("remote_path", "status/{asset}.json")
    CONFIG_TOKEN = text("token")
    CONFIG_TOKEN_FILE = text("token_file")

    def number(key, default):
        v = doc.get(key)
        if v is None or v is False:
            return default
        try:
            return int(v)
        except (TypeError, ValueError):
            return default

    PUSH_INTERVAL_HOURS = number("push_interval_hours", 12)
    IDLE_THRESHOLD_MS = number("idle_threshold_ms", 600000)
    TIMEOUT_SECONDS = number("timeout_seconds", 60)

    def field(key):
        v = doc.get(key)
        if v is None or v is False:
            return ""
        return str(v)

    # Get-Registration: config values are trimmed for validation; the
    # asset code keeps its case (registration upper-cased it before
    # saving; validation itself is case-insensitive, like -match).
    ASSET = field("asset_code").strip()
    EMPLOYEE = normalize_employee(field("employee_id").strip())
    SERIAL = field("serial")


def get_token():
    """Token precedence: env override > inline token > token file."""
    env = os.environ.get("BLUE_AGENT_TOKEN", "")
    if env:
        return env
    if CONFIG_TOKEN:
        return CONFIG_TOKEN
    if CONFIG_TOKEN_FILE and os.access(CONFIG_TOKEN_FILE, os.R_OK):
        try:
            return "".join(Path(CONFIG_TOKEN_FILE).read_text(encoding="utf-8").split())
        except (OSError, ValueError):
            return ""
    return ""


# --------------------------------------------------------------- run log --

def run_log_path():
    base = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local/state")
    return os.path.join(base, "blue-agent", "run.log")


def init_run_log():
    """Add-Content -Encoding UTF8 starts a fresh file with a UTF-8 BOM
    and appends lines with the Windows newline; mirror both so the
    uploaded log is byte-compatible with a Windows agent's run.log."""
    global RUN_LOG
    RUN_LOG = run_log_path()
    try:
        os.makedirs(os.path.dirname(RUN_LOG), exist_ok=True)
        if not os.path.exists(RUN_LOG) or os.path.getsize(RUN_LOG) == 0:
            with open(RUN_LOG, "ab") as f:
                f.write(b"\xef\xbb\xbf")
    except OSError:
        pass


def log(msg, level="INFO"):
    """Write-Log equivalent: stdout (→ the journal) plus the persistent
    run log. Never emit the access token."""
    msg = re.sub(r"access_token=[^&\s]+", "access_token=***", msg)
    line = f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} [{level}] {msg}"
    print(line, flush=True)
    if RUN_LOG:
        try:
            with open(RUN_LOG, "a", encoding="utf-8", newline="") as f:
                f.write(line + "\r\n")
        except OSError:
            pass


def err(msg):
    """Write-Error equivalent: stderr only, deliberately not part of
    run.log (the original's Write-Error goes to the error stream)."""
    print(msg, file=sys.stderr, flush=True)


# -------------------------------------------------------------- identity --

def get_serial():
    """Get-SerialNumber of the original: the `serial` hardcoded in the
    sops config first (the DMI sysfs files are root-only), then the DMI
    system serial (Win32_ComputerSystemProduct), then the board serial
    (Win32_BIOS), then the chassis serial (Win32_SystemEnclosure), then
    "GUID-<machine-id>" (the MachineGuid fallback), else the same
    literal the original returns. BLUE_AGENT_SERIAL_FILE overrides the
    source (for testing). Values are trimmed exactly like the
    original's .Trim() — whitespace at the ends only, interior
    preserved — and a source that trims to empty falls through to the
    next."""
    v = SERIAL.strip()
    if v:
        return v
    sources = [
        os.environ.get("BLUE_AGENT_SERIAL_FILE", ""),
        "/sys/class/dmi/id/product_serial",
        "/sys/class/dmi/id/board_serial",
        "/sys/class/dmi/id/chassis_serial",
    ]
    for f in sources:
        if not f or not os.access(f, os.R_OK):
            continue
        try:
            v = Path(f).read_text(encoding="utf-8", errors="replace").strip()
        except OSError:
            continue
        if v:
            return v
    if os.access("/etc/machine-id", os.R_OK):
        try:
            v = Path("/etc/machine-id").read_text(encoding="utf-8", errors="replace").strip()
        except OSError:
            v = ""
        if v:
            return f"GUID-{v}"
    return "无法获取机器SN号"


def session_state():
    """"active" when the user has an active logind session whose idle
    time (IdleSinceHint, set by the desktop environment) is below the
    threshold. Mirrors the intended-but-broken WTS logic of the
    original."""
    uid = str(os.getuid())
    user = pwd.getpwuid(os.getuid()).pw_name
    now_us = int(time.time() * 1_000_000)

    sessions = []
    try:
        out = subprocess.run(
            ["loginctl", "--no-legend", "list-sessions"],
            capture_output=True, text=True,
        ).stdout
        for line in out.splitlines():
            f = line.split()
            if len(f) >= 3 and f[1] == uid and f[2] == user:
                sessions.append(f[0])
    except Exception:
        sessions = []
    if not sessions:
        return "idle"

    has_active = False
    best = None
    for sid in sessions:
        try:
            out = subprocess.run(
                ["loginctl", "show-session", sid,
                 "-p", "State", "-p", "IdleHint", "-p", "IdleSinceHint"],
                capture_output=True, text=True,
            ).stdout
        except Exception:
            continue
        props = {}
        for line in out.splitlines():
            if "=" in line:
                k, val = line.split("=", 1)
                props[k] = val
        if props.get("State") != "active":
            continue
        has_active = True
        idle_since = 0
        try:
            idle_since = int(props.get("IdleSinceHint") or "0")
        except ValueError:
            idle_since = 0
        if props.get("IdleHint") == "true" and idle_since > 0:
            idle_ms = max(0, (now_us - idle_since) // 1000)
        else:
            idle_ms = 0
        if best is None or idle_ms < best:
            best = idle_ms
    if not has_active:
        return "idle"
    if best < IDLE_THRESHOLD_MS:
        return "active"
    return "idle"


# ------------------------------------------------------------ validation --

ASSET_RE = re.compile(r"^[AaMm][0-9]{9,12}$")  # -match is case-insensitive
EMPLOYEE_RE = re.compile(r"^(300[0-9]{5}|00[0-9]{6}|[0-9]{6})$")


def valid_asset(v):
    return bool(ASSET_RE.match(v))


def valid_employee(v):
    return bool(EMPLOYEE_RE.match(v))


def normalize_employee(v):
    """Format-EmployeeId: 6-digit ids not starting with 300/00 get a
    "00" prefix."""
    if re.match(r"^[0-9]{6}$", v) and not v.startswith("300") and not v.startswith("00"):
        return "00" + v
    return v


# ------------------------------------------------------------------ push --

def build_payload(sn, sstate):
    return {
        "sn": sn,
        "asset_code": ASSET,
        "employee_id": EMPLOYEE,
        "timestamp": datetime.now().astimezone().isoformat(timespec="seconds"),
        "session_state": sstate,
    }


def remote_path_for(sn):
    path = REMOTE_PATH_TEMPLATE.replace("{machine}", sn).replace("{asset}", ASSET)
    # main: .TrimStart('/')
    return path.lstrip("/")


def _ps_str(v):
    """ConvertTo-Json string form (Windows PowerShell 5.1): non-ASCII
    and HTML-sensitive characters as \\uXXXX escapes."""
    return (json.dumps(v, ensure_ascii=True)
            .replace("<", "\\u003c")
            .replace(">", "\\u003e")
            .replace("&", "\\u0026")
            .replace("'", "\\u0027"))


def ps_serialize(obj, indent=0):
    """Serialize a JSON document the way the original's ConvertTo-Json
    does (Windows PowerShell 5.1): CRLF line endings, 4-space indent
    steps, two spaces after each colon, no trailing newline. Verified
    byte-for-byte against the status/ files the fleet's Windows agents
    write."""
    if isinstance(obj, dict):
        if not obj:
            return "{}"
        parts = [
            " " * (indent + 4) + _ps_str(k) + ":  " + ps_serialize(v, indent + 4)
            for k, v in obj.items()
        ]
        return "{\r\n" + ",\r\n".join(parts) + "\r\n" + " " * indent + "}"
    if isinstance(obj, list):
        if not obj:
            return "[]"
        parts = [" " * (indent + 4) + ps_serialize(e, indent + 4) for e in obj]
        return "[\r\n" + ",\r\n".join(parts) + "\r\n" + " " * indent + "]"
    return _ps_str(obj)


def _net_error_message(e, host):
    """The .NET WebException.Message Invoke-RestMethod would have shown
    for a network-level failure — the original logs it after
    "网络波动"/"run.log 上传失败"/"执行失败", so it is reconstructed from
    the Python exception."""
    if isinstance(e, TimeoutError):
        # socket.timeout has been an alias of TimeoutError since 3.10
        return "The operation has timed out"
    if isinstance(e, socket.gaierror):
        return f"The remote name could not be resolved: '{host}'"
    if isinstance(e, ssl.SSLCertVerificationError):
        return "Could not establish trust relationship for the SSL/TLS secure channel."
    return "Unable to connect to the remote server"


def http_error_message(code, msg):
    """The .NET WebException.Message for a failed Invoke-RestMethod
    call. For an HTTP error it reads "The remote server returned an
    error: (<code>) <reason>." (reason = the server's status phrase,
    exactly what HttpWebResponse.StatusDescription carries); a
    network failure (code 0) already carries its message."""
    if code == 0:
        return msg
    return f"The remote server returned an error: ({code}) {msg}."


def http_request(method, uri, body=None):
    """One HTTP call with the original's headers (Get-ApiHeaders: UA +
    Content-Type; no Accept). http.client is used instead of
    urllib.request so the wire matches the bash port's curl exactly —
    no Accept-Encoding, no Connection; Host and (for a body)
    Content-Length are the only headers the transport itself adds.
    Returns (status, response_bytes, message); the message is the
    server's reason phrase, or for a network-level failure the
    .NET-style WebException text (status 0, like the original's
    catch-all code 0)."""
    conn = None
    u = None
    try:
        u = urllib.parse.urlsplit(uri)
        if u.scheme == "https":
            conn = http.client.HTTPSConnection(u.hostname, u.port, timeout=TIMEOUT_SECONDS)
        else:
            conn = http.client.HTTPConnection(u.hostname, u.port, timeout=TIMEOUT_SECONDS)
        target = u.path or "/"
        if u.query:
            target += "?" + u.query
        # skip_accept_encoding: both urllib.request and plain
        # conn.request() add "Accept-Encoding: identity"; the bash
        # port's curl sent neither that nor a Connection header, and
        # neither does PS 5.1's WebRequest.
        conn.putrequest(method, target, skip_accept_encoding=True)
        conn.putheader("User-Agent", AGENT_UA)
        conn.putheader("Content-Type", "application/json")
        if body is not None:
            conn.putheader("Content-Length", str(len(body)))
        conn.endheaders(body)
        resp = conn.getresponse()
        return resp.status, resp.read(), resp.reason
    except Exception as e:
        return 0, b"", _net_error_message(e, u.hostname if u else "")
    finally:
        if conn is not None:
            conn.close()


def api_uri(remote_path, token):
    # Get-ApiUri: $base already trimmed, token as a query parameter.
    return f"{API_ENDPOINT}/repos/{OWNER}/{REPO}/contents/{remote_path}?access_token={token}"


def get_remote_file(uri):
    """Get-RemoteFile -NoRetry of the original: one GET attempt. Any
    failure is logged exactly like the original and reported as "no
    remote file" — the surrounding retry loops of push_heartbeat and
    push_run_log absorb it, the way v0.9.21 uses Get-RemoteFile
    -NoRetry inside its own retry loops."""
    code, raw, _ = http_request("GET", uri)
    if code == 200:
        sha = ""
        existing = ""
        try:
            doc = json.loads(raw)
            if isinstance(doc, dict):
                sha = str(doc.get("sha") or "")
                content_b64 = str(doc.get("content") or "")
                if content_b64:
                    existing = base64.b64decode(
                        re.sub(r"\s+", "", content_b64)).decode("utf-8", "replace")
        except Exception:
            sha = ""
            existing = ""
        return sha, existing
    if code == 404:
        # 404 = 文件真不存在，立即返回不重试（避免无谓等待）
        log(f"远端文件不存在(404): {uri}", "WARN")
    elif code in (401, 403):
        # 401/403 = 鉴权失败（token 失效），重试也不会成功
        log(f"远端文件鉴权失败({code}): {uri}", "ERROR")
    else:
        log(f"获取远端文件失败(HTTP={code}, NoRetry模式不重试): {uri}", "WARN")
    return "", ""


_UNPARSEABLE = object()


def push_heartbeat(remote_path, heartbeat, token, force):
    """Append one heartbeat to the remote JSON array via the GitCode
    contents API — Push-Heartbeat of the original v0.9.21: 60 rounds,
    one un-retried GET (sha + content) per round, sha/git-ref conflicts
    (409/422/400) and 429 rate limiting with dedicated backoffs. The
    remote array doubles as the throttle state (stateless port):
    returns 2 (skip) when its last heartbeat is fresher than
    push_interval_hours and the caller did not pass --force."""
    global HEARTBEAT_ERROR
    uri = api_uri(remote_path, token)

    for attempt in range(1, 61):
        sha, existing = get_remote_file(uri)

        # Throttle: the remote array is the state (the original reads
        # its state.json, which a stateless port cannot). Skip when
        # its last heartbeat is fresher than push_interval_hours,
        # unless forced. An unparseable timestamp counts as "never".
        # The log line is the original's verbatim.
        if force != "--force" and existing:
            last_ts = ""
            try:
                probe = json.loads(existing)
                if isinstance(probe, list) and probe and isinstance(probe[-1], dict):
                    last_ts = str(probe[-1].get("timestamp") or "")
            except Exception:
                last_ts = ""
            if last_ts:
                try:
                    last_dt = datetime.fromisoformat(last_ts.replace("Z", "+00:00"))
                    if last_dt.tzinfo is None:
                        last_dt = last_dt.astimezone()
                    delta = (datetime.now(timezone.utc) - last_dt).total_seconds()
                    if delta < PUSH_INTERVAL_HOURS * 3600:
                        log(f"离上次上报不足 {PUSH_INTERVAL_HOURS} 小时，跳过。")
                        return 2
                except ValueError:
                    pass

        if not existing:
            # Push-Heartbeat on a missing file: `@($Heartbeat) |
            # ConvertTo-Json` — the pipeline unwraps the single
            # element, so the first push writes a bare object (the
            # fleet's first-push files look exactly like this).
            new_json = heartbeat
        else:
            try:
                doc = json.loads(existing)
            except ValueError:
                doc = _UNPARSEABLE
            if doc is _UNPARSEABLE:
                # The original's Write-Error stream, then a rebuild
                # from scratch: it emits `[null, …]` here (its @($null)
                # unwrap) — kept as a deliberate fix.
                err(f"现有文件内容解析失败(改为整体重建): {existing[:120]}")
                new_json = [heartbeat]
            elif doc is None:
                new_json = [heartbeat]
            elif isinstance(doc, list):
                new_json = doc + [heartbeat]
                if len(new_json) == 1:
                    new_json = new_json[0]
            else:
                # Parseable non-array document: @(...) keeps it as
                # the first element, like the original.
                new_json = [doc, heartbeat]

        content = ps_serialize(new_json)
        content_b64 = base64.b64encode(content.encode("utf-8")).decode("ascii")
        body = {"content": content_b64, "message": "heartbeat append"}
        if sha:
            body["sha"] = sha

        code, raw, msg = http_request("PUT" if sha else "POST", uri,
                                      json.dumps(body, separators=(",", ":")).encode("utf-8"))
        if code in (200, 201):
            return 0
        resp = raw.decode("utf-8", "replace")
        # The Exception.Message the original appends to its WARN lines
        # and re-raises to the main catch.
        exc = http_error_message(code, msg)
        log(f"heartbeat 写入失败 HTTP={code} body={resp} URI={uri}", "WARN")
        if attempt < 60:
            n = min(attempt - 1, 4)
            # 422/409 = sha 冲突，400 = git ref 锁冲突（多机并发写），均重试
            if code in (409, 422, 400):
                delay = 2 ** n + random.randrange(21)
                log(f"写入冲突(HTTP={code})，等待 {delay}s 后重试（第 {attempt}/60 轮）", "WARN")
                time.sleep(delay)
                continue
            # 429 = 限流（多台共用 token，GitCode 限 25 次/分钟/用户）：
            # 首次等满一个限流窗口，之后逐轮递增，叠加抖动防同步重试
            if code == 429:
                delay = 60 + (attempt - 1) * 30 + random.randrange(21)
                log(f"触发限流(HTTP=429)，等待 {delay}s 后重试（第 {attempt}/60 轮，限流窗口 25 次/分钟）", "WARN")
                time.sleep(delay)
                continue
            if code == 0 or code >= 500:
                log(f"网络波动，等待 {2 ** n}s 后重试（第 {attempt}/60 轮）: {exc}", "WARN")
                time.sleep(2 ** n)
                continue
        # The original's Write-Error ("heartbeat 上报失败: " + the .NET
        # message) goes to stderr; the main catch then logs
        # "执行失败: <the same message>" to run.log.
        HEARTBEAT_ERROR = exc
        err(f"heartbeat 上报失败: {exc}")
        return 1
    # Unreachable in practice (round 60 falls through above, exactly
    # like the original's foreach), kept for structural parity.
    HEARTBEAT_ERROR = "heartbeat 上报失败：60 轮重试后仍失败。"
    err(HEARTBEAT_ERROR)
    return 1


def push_run_log(token):
    """Push-RunLog of the original: upload the persistent run log to
    asset_run_log/<asset>_run.log after every heartbeat attempt
    (success or failure) for remote diagnostics. A log over 512KB is
    tail-cut to the newest 512KB; 10 retry rounds reusing the
    heartbeat's backoff strategy; failures never affect the main
    flow."""
    if not ASSET:
        log("资产编码为空，跳过 run.log 上传", "WARN")
        return
    if not RUN_LOG or not os.path.isfile(RUN_LOG):
        log(f"run.log 不存在（{RUN_LOG}），跳过日志上传", "WARN")
        return
    remote_path = f"asset_run_log/{ASSET}_run.log"
    uri = api_uri(remote_path, token)

    # The original reads the bytes *before* logging the WARN, so the
    # uploaded log does not contain the WARN line itself.
    try:
        data = Path(RUN_LOG).read_bytes()
    except OSError:
        data = b""
    if len(data) > 512 * 1024:
        data = data[-512 * 1024:]
        log("run.log 超过 512KB，仅上传末尾 512KB（最近日志）", "WARN")
    content_b64 = base64.b64encode(data).decode("ascii")

    for attempt in range(1, 11):
        sha, _ = get_remote_file(uri)
        body = {"content": content_b64, "message": f"run.log update for {ASSET}"}
        if sha:
            body["sha"] = sha

        code, raw, msg = http_request("PUT" if sha else "POST", uri,
                                      json.dumps(body, separators=(",", ":")).encode("utf-8"))
        if code in (200, 201):
            log(f"run.log 已上传至 {remote_path}")
            return
        resp = raw.decode("utf-8", "replace")
        log(f"run.log 上传失败 HTTP={code} body={resp} URI={uri}: {http_error_message(code, msg)}", "WARN")
        # 422/409/400 = git ref 锁冲突（心跳刚提交），429 = 限流，
        # 5xx/网络 = 波动 —— 复用心跳的退避策略
        retryable = code in (409, 422, 400, 429, 0) or code >= 500
        if attempt < 10 and retryable:
            if code == 429:
                delay = 60 + (attempt - 1) * 30 + random.randrange(21)
            else:
                delay = 2 ** min(attempt - 1, 4) + random.randrange(21)
            log(f"run.log 等待 {delay}s 后重试（第 {attempt}/10 轮，HTTP={code}）", "WARN")
            time.sleep(delay)
            continue
        log("run.log 上传最终失败（10 轮重试后仍失败），本次跳过", "WARN")
        return
    log("run.log 上传最终失败（10 轮重试后仍失败），本次跳过", "WARN")


# ------------------------------------------------------------- commands --

def cmd_run(force):
    # main of the original logs the run identity; the Windows
    # SYSTEM-vs-elevated audit branch that follows has no Linux
    # equivalent (running unprivileged is the design here).
    log(f"agent 启动 (v{AGENT_VERSION}) 运行身份={socket.gethostname()}\\{pwd.getpwuid(os.getuid()).pw_name}")

    # Registration is declarative (sops): invalid values are a config
    # error, not something to prompt for.
    if not valid_asset(ASSET):
        log(f"配置中的资产编码缺失或格式不对（首位 A/M + 9~12 位数字）: {ASSET or '<空>'} — 请检查 {CONFIG_FILE}", "ERROR")
        sys.exit(1)
    if not valid_employee(EMPLOYEE):
        log(f"配置中的员工工号缺失或格式不对（300xxxxx / 00xxxxxx / 6 位数字）: {EMPLOYEE or '<空>'} — 请检查 {CONFIG_FILE}", "ERROR")
        sys.exit(1)

    token = get_token()
    if not token:
        log("未配置 GitCode token（gitcode.token 或 gitcode.token_file）", "ERROR")
        sys.exit(1)

    sn = get_serial()
    sstate = session_state()
    heartbeat = build_payload(sn, sstate)
    remote_path = remote_path_for(sn)

    log(f"开始上报: SN={sn} 资产={ASSET} 工号={EMPLOYEE} 状态={sstate}")

    global HEARTBEAT_ERROR
    try:
        rc = push_heartbeat(remote_path, heartbeat, token, force)
    except Exception as e:  # the original's main catch-all
        HEARTBEAT_ERROR = str(e) or e.__class__.__name__
        rc = 1

    if rc == 0:
        # Update-State has no stateless equivalent; the message mirrors
        # the original verbatim.
        log("心跳已上报完成，写入状态文件。")
        # 心跳成功后上传本机 run.log（失败不影响主流程）
        try:
            push_run_log(token)
        except Exception as e:
            log(f"run.log 上传异常: {e}", "WARN")
        return
    if rc == 2:
        # Throttled against the remote state — the original also exits
        # before Push-RunLog on this path.
        sys.exit(0)
    reason = HEARTBEAT_ERROR or "心跳未上报"
    log(f"执行失败: {reason}", "ERROR")
    # 失败时也上传 run.log（含完整失败信息，远程诊断价值最高）
    try:
        push_run_log(token)
    except Exception as e:
        log(f"run.log 上传异常: {e}", "WARN")
    err(reason)
    sys.exit(1)


def cmd_status():
    sn = get_serial()
    sstate = session_state()
    token_status = "ok" if get_token() else "missing"
    payload = build_payload(sn, sstate)
    remote_path = remote_path_for(sn)
    print(f"agent version : {AGENT_VERSION}")
    print(f"config        : {CONFIG_FILE}")
    print(f"serial        : {sn}")
    print(f"session state : {sstate}")
    print(f"asset code    : {ASSET or '<未配置>'}")
    print(f"employee id   : {EMPLOYEE or '<未配置>'}")
    print(f"token         : {token_status}")
    print(f"throttle      : remote last heartbeat (≤ {PUSH_INTERVAL_HOURS}h; --force overrides)")
    print(f"run log       : {run_log_path()}")
    print(f"remote path   : {remote_path}")
    print(f"payload       : {json.dumps(payload, ensure_ascii=False, separators=(',', ':'))}")


def usage(file=sys.stdout):
    print(f"""{AGENT_NAME} v{AGENT_VERSION} — BlueZone 资产心跳 agent（Linux 无特权版）

用法:
  blue-agent [run [--force]]   上报心跳（默认动作；--force 忽略节流）
  blue-agent status            查看配置/登记/心跳预览（不做网络请求）

资产编码、员工工号与 GitCode token 均在 sops 配置中写死
（secrets/<host>-blue-agent.yaml → /run/secrets/rendered/blue-agent.json），
修改后需要 nixos-rebuild 生效。

环境:
  BLUE_AGENT_CONFIG            配置文件路径（默认依次查找
                               /run/secrets/rendered/blue-agent.json、
                               /etc/blue-agent/config.json）
  BLUE_AGENT_TOKEN             直接提供 token（优先于配置文件）

节流: 远端心跳数组最后一条的时间戳（默认 12h；--force 忽略）
本地日志: ~/.local/state/blue-agent/run.log（持久积累；每次心跳后上传至
          asset_run_log/<asset>_run.log，超过 512KB 仅上传末尾 512KB）
控制台: 标准输出（定时任务见 journalctl --user -u blue-agent）""", file=file, flush=True)


def main(argv):
    cmd = argv[1] if len(argv) > 1 else "run"
    if cmd == "run":
        rest = argv[2:]
        # The run log must exist before load_config, so config errors
        # are logged to it like the original's Write-Log.
        init_run_log()
        load_config()
        cmd_run(rest[0] if rest else "")
    elif cmd == "status":
        load_config()
        cmd_status()
    elif cmd in ("help", "-h", "--help"):
        usage()
    else:
        usage(sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv)
