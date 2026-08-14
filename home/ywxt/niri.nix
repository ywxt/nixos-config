{ ... }:

{
  xdg.configFile = {
    "niri/config.kdl".source = ./niri/config.kdl;
    "niri/animation.kdl".source = ./niri/animation.kdl;
    "niri/keybindings.kdl".source = ./niri/keybindings.kdl;
    "niri/windowrules.kdl".source = ./niri/windowrules.kdl;
    "uwsm/default-id".text = "niri.desktop\n";
  };
}
