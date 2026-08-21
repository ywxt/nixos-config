{ lib, osConfig, ... }:

let
  inherit (lib) concatMapStringsSep optionalString;

  quote = builtins.toJSON;
  renderMonitor = monitor: ''
    output ${quote monitor.name} {
        ${optionalString (!monitor.enabled) "off"}
        ${optionalString (monitor.mode != null) "mode ${quote monitor.mode}"}
        scale ${toString monitor.scale}
        transform ${quote monitor.transform}
        ${optionalString (monitor.position != null) "position x=${toString monitor.position.x} y=${toString monitor.position.y}"}
    }
  '';
in

{
  xdg.configFile = {
    "niri/config.kdl".source = ./niri/config.kdl;
    "niri/outputs.kdl".text = concatMapStringsSep "\n" renderMonitor osConfig.desktop.monitors;
    "niri/animation.kdl".source = ./niri/animation.kdl;
    "niri/keybindings.kdl".source = ./niri/keybindings.kdl;
    "niri/windowrules.kdl".source = ./niri/windowrules.kdl;
  };
}
