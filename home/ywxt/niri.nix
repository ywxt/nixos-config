{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  inherit (lib) concatMapStringsSep mapAttrsToList optionalString;

  quote = builtins.toJSON;
  renderMonitor = monitor: ''
    output ${quote monitor.name} {
        ${optionalString (!monitor.enabled) "off"}
        ${optionalString (monitor.mode != null) "mode ${quote monitor.mode}"}
        scale ${toString monitor.scale}
        transform ${quote monitor.transform}
        ${optionalString (
          monitor.position != null
        ) "position x=${toString monitor.position.x} y=${toString monitor.position.y}"}
    }
  '';
  outputs = pkgs.writeText "niri-outputs.kdl" (
    concatMapStringsSep "\n" renderMonitor osConfig.desktop.monitors
  );
  environment = lib.concatStringsSep "\n" (
    mapAttrsToList (
      name: value: "    ${name} ${builtins.toJSON (toString value)}"
    ) config.environment.sessionVariables
  );
  mainConfig = pkgs.writeText "niri-config.kdl" ''
    environment {
    ${environment}
    }
    // Generated from the host's desktop.monitors option by Home Manager.
    include "outputs.kdl"

    ${builtins.readFile ./niri/config.kdl}
    spawn-at-startup "noctalia"
  '';
  validatedConfig = pkgs.runCommand "niri-config" { nativeBuildInputs = [ pkgs.niri ]; } ''
    mkdir -p $out
    cp ${mainConfig} $out/config.kdl
    cp ${outputs} $out/outputs.kdl
    cp ${./niri/animation.kdl} $out/animation.kdl
    cp ${./niri/keybindings.kdl} $out/keybindings.kdl
    cp ${./niri/windowrules.kdl} $out/windowrules.kdl
    niri validate -c $out/config.kdl
  '';
in

{
  packages = with pkgs; [
    xwayland-satellite
    wl-clipboard
    cliphist
  ];

  xdg.config.files = {
    "niri/config.kdl" = {
      clobber = true;
      source = "${validatedConfig}/config.kdl";
    };
    "niri/outputs.kdl" = {
      clobber = true;
      source = "${validatedConfig}/outputs.kdl";
    };
    "niri/animation.kdl" = {
      clobber = true;
      source = "${validatedConfig}/animation.kdl";
    };
    "niri/keybindings.kdl" = {
      clobber = true;
      source = "${validatedConfig}/keybindings.kdl";
    };
    "niri/windowrules.kdl" = {
      clobber = true;
      source = "${validatedConfig}/windowrules.kdl";
    };
  };
}
