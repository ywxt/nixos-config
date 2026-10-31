{
  config,
  lib,
  pkgs,
  ...
}:

# Unprivileged Linux port of the Windows BlueZoneAssetManager agent
# (blue/agent.ps1). The agent runs entirely as a regular user:
#
#   * a systemd *user* timer (not a SYSTEM task) drives the heartbeat;
#   * the entire configuration — GitCode endpoint, token, and the
#     hardcoded asset code / employee id / hardware serial — is
#     rendered by sops-nix into
#     /run/secrets/rendered/blue-agent.json (0400, owned by the
#     auto-detected agent user); nothing lives in /etc or $HOME;
#   * the agent keeps no state of its own: the 12h throttle uses the
#     last timestamp in the remote heartbeat array. The one persistent
#     file is the run log (XDG_STATE_HOME/blue-agent/run.log), which
#     the agent uploads to asset_run_log/<asset>_run.log after each
#     heartbeat — the counterpart of the original's log\run.log and
#     Push-RunLog; console output goes to the journal.
#   * the hardware serial is hardcoded in the sops file (the DMI sysfs
#     files are root-only, so the unprivileged agent cannot read what
#     the original read via WMI under SYSTEM);
#
# Registration is declarative: edit secrets/<host>-blue-agent.yaml with
# sops-secrets and rebuild — there is no interactive registration and
# no self-update; this module and pkgs/blue-agent are rebuilt from this
# repository, replacing the original repo-pull + RSA update channel.
let
  cfg = config.services.blue-agent;

  # Human accounts declared on this host.
  normalUsers = lib.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);

  # Auto-detected: the host's sole human account.
  agentUser = if lib.length normalUsers == 1 then lib.head normalUsers else null;
in
{
  options.services.blue-agent = {
    enable = lib.mkEnableOption "BlueZone asset heartbeat agent (unprivileged, user-level timer)";

    package = lib.mkPackageOption pkgs "blue-agent" { };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 01:00:00";
      description = "OnCalendar expression for the heartbeat timer.";
    };

    pushIntervalHours = lib.mkOption {
      type = lib.types.ints.positive;
      default = 12;
      description = "Throttle: minimum hours between two heartbeats (matches the original agent).";
    };

    idleThresholdMs = lib.mkOption {
      type = lib.types.ints.positive;
      default = 600000;
      description = "Session idle threshold in milliseconds; above it the machine reports \"idle\".";
    };

    timeoutSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
      description = "Per-request HTTP timeout (honoured by the agent; the Windows agent defined but never used this).";
    };

    # sops file with `blue-agent: {token, asset-code, employee-id, serial}`.
    # Kept in sync with the default search path of the agent script:
    # /run/secrets/rendered/blue-agent.json.
    secretsFile = lib.mkOption {
      type = lib.types.path;
      default = ../secrets/ywxt-work-blue-agent.yaml;
      description = "sops file carrying the GitCode token and the hardcoded registration.";
    };

    gitcode = {
      apiEndpoint = lib.mkOption {
        type = lib.types.str;
        default = "https://api.gitcode.com/api/v5";
        description = "GitCode API base URL.";
      };

      owner = lib.mkOption {
        type = lib.types.str;
        default = "SoftwareEngineering";
        description = "GitCode repository owner.";
      };

      repo = lib.mkOption {
        type = lib.types.str;
        default = "BlueZoneAssetManager";
        description = "GitCode repository used as the heartbeat store.";
      };

      remotePath = lib.mkOption {
        type = lib.types.str;
        default = "status/{asset}.json";
        description = ''
          Remote path template for the heartbeat file, with {asset}
          and {machine} placeholders.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = agentUser != null;
        message = ''
          services.blue-agent: the agent user is auto-detected from the host's
          normal users (users.users.<name>.isNormalUser) and needs exactly one,
          but this host has ${toString (lib.length normalUsers)}
          (${lib.concatStringsSep ", " normalUsers}).
        '';
      }
    ];

    # Gated so a failed auto-detection surfaces the assertion above
    # instead of a null type error.
    sops = lib.mkIf (agentUser != null) {
      secrets = {
        "blue-agent/token" = {
          sopsFile = cfg.secretsFile;
          owner = agentUser;
          mode = "0400";
        };
        "blue-agent/asset-code" = {
          sopsFile = cfg.secretsFile;
          owner = agentUser;
          mode = "0400";
        };
        "blue-agent/employee-id" = {
          sopsFile = cfg.secretsFile;
          owner = agentUser;
          mode = "0400";
        };
        "blue-agent/serial" = {
          sopsFile = cfg.secretsFile;
          owner = agentUser;
          mode = "0400";
        };
      };

      # The complete agent config, rendered at activation. Placeholder
      # values are substituted verbatim, so the token must not contain
      # JSON-special characters (GitCode tokens are [A-Za-z0-9_-]).
      templates."blue-agent.json" = {
        owner = agentUser;
        mode = "0400";
        content = builtins.toJSON {
          gitcode = {
            api_endpoint = cfg.gitcode.apiEndpoint;
            owner = cfg.gitcode.owner;
            repo = cfg.gitcode.repo;
            remote_path = cfg.gitcode.remotePath;
            token = config.sops.placeholder."blue-agent/token";
          };
          push_interval_hours = cfg.pushIntervalHours;
          idle_threshold_ms = cfg.idleThresholdMs;
          timeout_seconds = cfg.timeoutSeconds;
          asset_code = config.sops.placeholder."blue-agent/asset-code";
          employee_id = config.sops.placeholder."blue-agent/employee-id";
          serial = config.sops.placeholder."blue-agent/serial";
        };
      };
    };

    environment.systemPackages = [ cfg.package ];

    systemd.user.services.blue-agent = {
      description = "BlueZone asset heartbeat agent (unprivileged)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/blue-agent";
      };
    };

    systemd.user.timers.blue-agent = {
      description = "Daily BlueZone asset heartbeat";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        # The original's Repair-TaskStartWhenAvailable (v0.9.21):
        # catch up a window missed while the machine slept.
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}
