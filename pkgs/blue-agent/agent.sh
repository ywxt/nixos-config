#!/usr/bin/env bash
# blue-agent — BlueZone asset heartbeat agent.
#
# Unprivileged Linux port of the Windows `blue/agent.ps1` agent (v0.9.4)
# from the BlueZoneAssetManager distribution. Key differences:
#
#   * Runs as a regular user (invoked by a systemd *user* timer); no
#     elevation anywhere. It keeps no local state: the whole
#     configuration — including the GitCode token and the hardcoded
#     asset code / employee id — is read from the sops-nix rendered
#     file /run/secrets/rendered/blue-agent.json (owner-only), and the
#     12h throttle consults the last timestamp in the remote heartbeat
#     array, which the push fetches anyway (transient HTTP scratch in
#     TMPDIR aside). Logging goes to stdout → the journal.
#   * No self-update: the script is built from this repository and
#     replaced by `nixos-rebuild`. This replaces the original
#     repo-pull + RSA-signature self-update mechanism, which has no
#     equivalent in a declarative deployment.
#   * No interactive registration: the asset code and employee id are
#     declared in secrets/ywxt-work-blue-agent.yaml (sops) and baked
#     into the rendered config at activation.
#   * The serial-number chain mirrors Get-SerialNumber of the original
#     exactly: the `serial` hardcoded in the sops config first (the
#     DMI sysfs files are root-only, so the unprivileged agent cannot
#     read them directly), then the DMI system serial
#     (Win32_ComputerSystemProduct), then the board serial (standing
#     in for Win32_BIOS), then the chassis serial
#     (Win32_SystemEnclosure), then "GUID-<machine-id>" (the
#     original's MachineGuid fallback), else the same literal fallback
#     string.
#   * Idle detection uses logind (IdleHint / IdleSinceHint) instead of
#     WTSQuerySessionInformation, fixing the original bug where info
#     class 4 (WTSSessionId, a small session number) was compared
#     against the idle threshold, so the state was always "active".
#   * The remote heartbeat file is serialized exactly like the
#     original's ConvertTo-Json (Windows PowerShell 5.1): CRLF line
#     endings, 4-space indent steps, two spaces after each colon, no
#     trailing newline — and a first push writes a bare object, the
#     pipeline-unwrap artifact the fleet's Windows agents show in
#     their status/ files. HTTP requests carry the original's headers
#     (User-Agent "BlueZoneAgent").
#   * When the remote heartbeat file cannot be parsed it is rebuilt as
#     a fresh array, fixing the original bug that produced
#     `[null, {...}]` entries; a parseable non-array document is
#     wrapped like the original's @(...), not dropped.
#   * `timeout_seconds` from the config is actually honoured (curl -m).
#
# Usage: blue-agent [run [--force] | status | help]
set -euo pipefail

AGENT_NAME="blue-agent"
AGENT_VERSION="1.0.0"
# Get-ApiHeaders of the original, verbatim.
AGENT_UA="BlueZoneAgent"

# Config resolution: explicit override, sops-nix rendered template
# (keep in sync with modules/blue-agent.nix), /etc fallback.
if [[ -n ${BLUE_AGENT_CONFIG:-} ]]; then
    CONFIG_FILE=$BLUE_AGENT_CONFIG
elif [[ -r /run/secrets/rendered/blue-agent.json ]]; then
    CONFIG_FILE=/run/secrets/rendered/blue-agent.json
else
    CONFIG_FILE=/etc/blue-agent/config.json
fi

# Temp files for HTTP response bodies, cleaned up on exit — the only
# files the agent ever touches.
GET_FILE=""
PUT_FILE=""

# Journal-bound logging; never emit the access token.
log() {
    local msg=${1} level=${2:-INFO}
    msg=$(printf '%s' "$msg" | sed -E 's/access_token=[^&[:space:]]+/access_token=***/g')
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $msg"
}

# ---------------------------------------------------------------- config --

load_config() {
    if [[ ! -r $CONFIG_FILE ]]; then
        log "config not found or unreadable: $CONFIG_FILE (set BLUE_AGENT_CONFIG to override)" ERROR
        exit 1
    fi
    local cfg
    cfg=$(cat "$CONFIG_FILE")
    API_ENDPOINT=$(jq -r '.gitcode.api_endpoint // "https://api.gitcode.com/api/v5"' <<<"$cfg")
    # Get-ApiUri: $base.TrimEnd('/')
    while [[ $API_ENDPOINT == */ ]]; do API_ENDPOINT=${API_ENDPOINT%/}; done
    OWNER=$(jq -r '.gitcode.owner // "SoftwareEngineering"' <<<"$cfg")
    REPO=$(jq -r '.gitcode.repo // "BlueZoneAssetManager"' <<<"$cfg")
    REMOTE_PATH_TEMPLATE=$(jq -r '.gitcode.remote_path // "status/{asset}.json"' <<<"$cfg")
    CONFIG_TOKEN=$(jq -r '.gitcode.token // empty' <<<"$cfg")
    CONFIG_TOKEN_FILE=$(jq -r '.gitcode.token_file // empty' <<<"$cfg")
    PUSH_INTERVAL_HOURS=$(jq -r '.push_interval_hours // 12' <<<"$cfg")
    IDLE_THRESHOLD_MS=$(jq -r '.idle_threshold_ms // 600000' <<<"$cfg")
    TIMEOUT_SECONDS=$(jq -r '.timeout_seconds // 60' <<<"$cfg")
    ASSET=$(jq -r '.asset_code // empty' <<<"$cfg")
    EMPLOYEE=$(jq -r '.employee_id // empty' <<<"$cfg")
    SERIAL=$(jq -r '.serial // empty' <<<"$cfg")
    # Get-Registration: config values are trimmed for validation; the
    # asset code keeps its case (registration upper-cased it before
    # saving; validation itself is case-insensitive, like -match).
    ASSET=$(trim "$ASSET")
    EMPLOYEE=$(normalize_employee "$(trim "$EMPLOYEE")")
}

# Token precedence: env override > inline token > token file.
get_token() {
    if [[ -n ${BLUE_AGENT_TOKEN:-} ]]; then
        printf '%s' "$BLUE_AGENT_TOKEN"
    elif [[ -n $CONFIG_TOKEN ]]; then
        printf '%s' "$CONFIG_TOKEN"
    elif [[ -n $CONFIG_TOKEN_FILE && -r $CONFIG_TOKEN_FILE ]]; then
        tr -d '[:space:]' < "$CONFIG_TOKEN_FILE"
    else
        return 1
    fi
}

# ------------------------------------------------------------- identity --

# Machine serial, mirroring Get-SerialNumber of the original: the
# `serial` hardcoded in the sops config comes first (the DMI sysfs
# files are root-only and unreadable without privileges), then the
# DMI system serial (Win32_ComputerSystemProduct), then the board
# serial (Win32_BIOS), then "GUID-<machine-id>" (the original's
# MachineGuid fallback), else the same literal the original returns.
# BLUE_AGENT_SERIAL_FILE overrides the source (for testing).
# Values are trimmed exactly like the original's .Trim() — whitespace
# at the ends only, interior preserved — and a source that trims to
# empty falls through to the next, as Get-SerialNumber does.
trim() {
    local v=$1
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    printf '%s' "$v"
}

get_serial() {
    local f v
    v=$(trim "${SERIAL:-}")
    if [[ -n $v ]]; then
        printf '%s' "$v"
        return 0
    fi
    for f in \
        "${BLUE_AGENT_SERIAL_FILE:-}" \
        /sys/class/dmi/id/product_serial \
        /sys/class/dmi/id/board_serial \
        /sys/class/dmi/id/chassis_serial
    do
        [[ -n $f && -r $f ]] || continue
        v=$(<"$f")
        v=$(trim "$v")
        if [[ -n $v ]]; then
            printf '%s' "$v"
            return 0
        fi
    done
    if [[ -r /etc/machine-id ]]; then
        printf 'GUID-%s' "$(</etc/machine-id)"
        return 0
    fi
    printf '无法获取机器SN号'
}

# --------------------------------------------------------- idle detection --

# "active" when the user has an active logind session whose idle time
# (IdleSinceHint, set by the desktop environment) is below the
# threshold. Mirrors the intended-but-broken WTS logic of the original.
session_state() {
    local uid user now_us sessions sid props
    local state idle_hint idle_since has_active=0 best="" idle_ms
    uid=$(id -u)
    user=$(id -un)
    now_us=$(( $(date +%s%N) / 1000 ))
    sessions=$(loginctl --no-legend list-sessions 2>/dev/null \
        | awk -v u="$uid" -v n="$user" '$2 == u && $3 == n {print $1}')
    if [[ -z $sessions ]]; then
        echo idle
        return 0
    fi
    for sid in $sessions; do
        props=$(loginctl show-session "$sid" -p State -p IdleHint -p IdleSinceHint 2>/dev/null) || continue
        state=$(sed -n 's/^State=//p' <<<"$props")
        [[ $state == active ]] || continue
        has_active=1
        idle_hint=$(sed -n 's/^IdleHint=//p' <<<"$props")
        idle_since=$(sed -n 's/^IdleSinceHint=//p' <<<"$props")
        [[ $idle_since =~ ^[0-9]+$ ]] || idle_since=0
        if [[ $idle_hint == true && $idle_since -gt 0 ]]; then
            idle_ms=$(( (now_us - idle_since) / 1000 ))
            if (( idle_ms < 0 )); then idle_ms=0; fi
        else
            idle_ms=0
        fi
        if [[ -z $best || $idle_ms -lt $best ]]; then
            best=$idle_ms
        fi
    done
    if (( has_active == 0 )); then
        echo idle
    elif (( best < IDLE_THRESHOLD_MS )); then
        echo active
    else
        echo idle
    fi
}

# ------------------------------------------------------------ validation --

asset_re='^[AaMm][0-9]{9,12}$' # -match is case-insensitive
employee_re='^(300[0-9]{5}|00[0-9]{6}|[0-9]{6})$'

valid_asset() { [[ $1 =~ $asset_re ]]; }
valid_employee() { [[ $1 =~ $employee_re ]]; }

# Mirrors Format-EmployeeId: 6-digit ids not starting with 300/00 get a
# "00" prefix.
normalize_employee() {
    local id=$1
    if [[ $id =~ ^[0-9]{6}$ && ! $id =~ ^300 && ! $id =~ ^00 ]]; then
        id="00$id"
    fi
    printf '%s' "$id"
}

# ----------------------------------------------------------------- push --

build_payload() {
    local sn=$1 sstate=$2
    jq -cn \
        --arg sn "$sn" \
        --arg asset "$ASSET" \
        --arg emp "$EMPLOYEE" \
        --arg ts "$(date '+%Y-%m-%dT%H:%M:%S%:z')" \
        --arg state "$sstate" \
        '{sn:$sn, asset_code:$asset, employee_id:$emp, timestamp:$ts, session_state:$state}'
}

remote_path_for() {
    local sn=$1 path=$REMOTE_PATH_TEMPLATE
    path=${path//'{machine}'/$sn}
    path=${path//'{asset}'/$ASSET}
    # main: .TrimStart('/')
    while [[ $path == /* ]]; do path=${path#/}; done
    printf '%s' "$path"
}

# Serialize a JSON document the way the original's ConvertTo-Json does
# (Windows PowerShell 5.1): CRLF line endings, 4-space indent steps,
# two spaces after each colon, no trailing newline. Verified
# byte-for-byte against the status/ files the fleet's Windows agents
# write.
ps_serialize() {
    jq -r '
      def e: tojson;
      if type == "array" then
        if length == 0 then "[]"
        else
          "[\r\n" +
          ([.[] |
            "    {\r\n" +
            (to_entries | map("        " + (.key | e) + ":  " + (.value | e)) | join(",\r\n")) +
            "\r\n    }"
          ] | join(",\r\n")) +
          "\r\n]"
        end
      elif type == "object" then
        "{\r\n" +
        (to_entries | map("    " + (.key | e) + ":  " + (.value | e)) | join(",\r\n")) +
        "\r\n}"
      else
        tojson
      end
    '
}

# Append one heartbeat to the remote JSON array via the GitCode
# contents API. Retries sha conflicts (409/422, re-GET) and server or
# network errors (exponential backoff), up to 10 rounds — the same
# strategy as Push-Heartbeat in the original agent. The remote array
# doubles as the throttle state: returns 2 (skip) when its last
# heartbeat is fresher than push_interval_hours and the caller did
# not pass --force.
push_heartbeat() {
    local remote_path=$1 payload=$2 token=$3 force=$4
    local uri attempt code sha content_b64 existing kind newjson new_text new_b64 body method n resp
    local last_ts last_epoch now_s
    uri="$API_ENDPOINT/repos/$OWNER/$REPO/contents/$remote_path?access_token=$token"

    for attempt in 1 2 3 4 5 6 7 8 9 10; do
        sha=""
        existing=""
        code=$(curl -sS -m "$TIMEOUT_SECONDS" \
            -H "User-Agent: $AGENT_UA" -H "Content-Type: application/json" \
            -o "$GET_FILE" -w '%{http_code}' "$uri" 2>/dev/null) || code=000

        if [[ $code == 200 ]]; then
            sha=$(jq -r '.sha // empty' "$GET_FILE" 2>/dev/null) || sha=""
            content_b64=$(jq -r '.content // empty' "$GET_FILE" 2>/dev/null | tr -d '[:space:]') || content_b64=""
            if [[ -n $content_b64 ]]; then
                existing=$(printf '%s' "$content_b64" | base64 -d 2>/dev/null) || existing=""
            fi
        elif [[ $code == 404 ]]; then
            : # first heartbeat for this asset — create below
        elif [[ $code == 000 || $code -ge 500 ]]; then
            n=$((attempt - 1))
            if (( n > 4 )); then n=4; fi
            log "网络波动(HTTP=$code)，等待 $((2 ** n))s 后重试（第 $attempt/10 轮）" WARN
            sleep $((2 ** n))
            continue
        else
            log "读取远端记录失败 HTTP=$code URI=$uri" ERROR
            return 1
        fi

        # Throttle: the remote array is the state. Skip when its last
        # heartbeat is fresher than push_interval_hours, unless forced.
        # An unparseable timestamp counts as "never".
        if [[ $force != "--force" && -n $existing ]]; then
            last_ts=$(jq -r 'if type == "array" and length > 0 then (.[-1].timestamp // empty) else empty end' <<<"$existing" 2>/dev/null) || last_ts=""
            if [[ -n $last_ts ]] && last_epoch=$(date -d "$last_ts" +%s 2>/dev/null); then
                now_s=$(date +%s)
                if (( now_s - last_epoch < PUSH_INTERVAL_HOURS * 3600 )); then
                    log "远端最后心跳（$last_ts）距今不足 $PUSH_INTERVAL_HOURS 小时，跳过。"
                    return 2
                fi
            fi
        fi

        if [[ -z $existing ]]; then
            # Push-Heartbeat on a missing file: `@($Heartbeat) |
            # ConvertTo-Json` — the pipeline unwraps the single
            # element, so the first push writes a bare object (the
            # fleet's first-push files look exactly like this).
            newjson=$payload
        else
            kind=$(jq -r 'type' <<<"$existing" 2>/dev/null) || kind="unparseable"
            case $kind in
                array)
                    newjson=$(jq -c --argjson h "$payload" \
                        '. + [$h] | if length == 1 then .[0] else . end' <<<"$existing")
                    ;;
                null | unparseable)
                    # Rebuild from scratch: the original emits
                    # `[null, …]` here — kept as a deliberate fix.
                    if [[ $kind == unparseable ]]; then
                        log "现有远端内容解析失败，整体重建" WARN
                    fi
                    newjson=$(jq -cn --argjson h "$payload" '[$h]')
                    ;;
                *)
                    # Parseable non-array document: @(...) keeps it as
                    # the first element, like the original.
                    newjson=$(jq -cn --argjson h "$payload" --argjson e "$existing" '[$e, $h]')
                    ;;
            esac
        fi

        new_text=$(ps_serialize <<<"$newjson")
        new_b64=$(printf '%s' "$new_text" | base64 -w0)
        body=$(jq -cn --arg c "$new_b64" --arg m "heartbeat append" --arg s "$sha" \
            'if $s == "" then {content:$c, message:$m} else {content:$c, message:$m, sha:$s} end')

        method=PUT
        if [[ -z $sha ]]; then method=POST; fi
        code=$(curl -sS -m "$TIMEOUT_SECONDS" -X "$method" \
            -H "User-Agent: $AGENT_UA" -H "Content-Type: application/json" \
            -d "$body" -o "$PUT_FILE" -w '%{http_code}' "$uri" 2>/dev/null) || code=000

        if [[ $code == 200 || $code == 201 ]]; then
            return 0
        elif [[ $code == 409 || $code == 422 ]]; then
            log "sha 冲突，重取后重试（第 $attempt/10 轮）" WARN
            continue
        elif [[ $code == 000 || $code -ge 500 ]]; then
            n=$((attempt - 1))
            if (( n > 4 )); then n=4; fi
            resp=$(head -c 300 "$PUT_FILE" 2>/dev/null) || resp=""
            log "heartbeat 写入失败 HTTP=$code body=$resp URI=$uri" WARN
            log "网络波动，等待 $((2 ** n))s 后重试（第 $attempt/10 轮）" WARN
            sleep $((2 ** n))
            continue
        else
            resp=$(head -c 300 "$PUT_FILE" 2>/dev/null) || resp=""
            log "heartbeat 上报失败 HTTP=$code body=$resp URI=$uri" ERROR
            return 1
        fi
    done
    log "heartbeat 上报失败：10 轮重试后仍失败。" ERROR
    return 1
}

# ------------------------------------------------------------- commands --

cmd_run() {
    local force=${1:-}

    log "agent 启动 (v$AGENT_VERSION)"

    # Registration is declarative (sops): invalid values are a config
    # error, not something to prompt for.
    if ! valid_asset "$ASSET"; then
        log "配置中的资产编码缺失或格式不对（首位 A/M + 9~12 位数字）: ${ASSET:-<空>} — 请检查 $CONFIG_FILE" ERROR
        exit 1
    fi
    if ! valid_employee "$EMPLOYEE"; then
        log "配置中的员工工号缺失或格式不对（300xxxxx / 00xxxxxx / 6 位数字）: ${EMPLOYEE:-<空>} — 请检查 $CONFIG_FILE" ERROR
        exit 1
    fi

    local token sn sstate payload remote_path rc

    if ! token=$(get_token); then
        log "未配置 GitCode token（gitcode.token 或 gitcode.token_file）" ERROR
        exit 1
    fi

    sn=$(get_serial)
    sstate=$(session_state)
    payload=$(build_payload "$sn" "$sstate")
    remote_path=$(remote_path_for "$sn")

    log "开始上报: SN=$sn 资产=$ASSET 工号=$EMPLOYEE 状态=$sstate"
    rc=0
    push_heartbeat "$remote_path" "$payload" "$token" "$force" || rc=$?
    case $rc in
        0) log "心跳已上报完成。" ;;
        2) exit 0 ;; # throttled against the remote state — already logged
        *)
            log "执行失败: 心跳未上报" ERROR
            exit 1
            ;;
    esac
}

cmd_status() {
    local sn sstate token_status payload remote_path
    sn=$(get_serial)
    sstate=$(session_state)
    if get_token >/dev/null 2>&1; then token_status="ok"; else token_status="missing"; fi
    payload=$(build_payload "$sn" "$sstate")
    remote_path=$(remote_path_for "$sn")
    echo "agent version : $AGENT_VERSION"
    echo "config        : $CONFIG_FILE"
    echo "serial        : $sn"
    echo "session state : $sstate"
    echo "asset code    : ${ASSET:-<未配置>}"
    echo "employee id   : ${EMPLOYEE:-<未配置>}"
    echo "token         : $token_status"
    echo "throttle      : remote last heartbeat (≤ ${PUSH_INTERVAL_HOURS}h; --force overrides)"
    echo "local state   : none — the agent writes no files"
    echo "remote path   : $remote_path"
    echo "payload       : $payload"
}

usage() {
    cat <<EOF
$AGENT_NAME v$AGENT_VERSION — BlueZone 资产心跳 agent（Linux 无特权版）

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
本地状态: 无 — 除自动清理的 HTTP 临时文件外，agent 不写任何本地文件
日志: 标准输出（定时任务见 journalctl --user -u blue-agent）
EOF
}

main() {
    GET_FILE=$(mktemp)
    PUT_FILE=$(mktemp)
    trap 'rm -f "$GET_FILE" "$PUT_FILE"' EXIT

    local cmd=${1:-run}
    case $cmd in
        run)
            shift || true
            load_config
            cmd_run "${1:-}"
            ;;
        status)
            load_config
            cmd_status
            ;;
        help | -h | --help)
            usage
            ;;
        *)
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"
