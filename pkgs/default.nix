final: _prev: {
  annepro2-udev-rules = final.callPackage ./annepro2-udev-rules.nix { };
  bot-gate = final.callPackage ./bot-gate.nix { };
  bot-metric = final.callPackage ./bot-metric.nix { };
  colloid-kvantum = final.callPackage ./colloid-kvantum.nix { };
  hdc = final.callPackage ./hdc.nix { };
  dayu200-flash = final.callPackage ./dayu200 { };
  ohos-build-env = final.callPackage ./ohos-build-env.nix { };
  project-brain = final.python3Packages.callPackage ./project-brain.nix { };
  rime-huma = final.callPackage ./rime-huma.nix { };
  rustbot-cli = final.callPackage ./rustbot-cli.nix { };
  th-tshyn = final.callPackage ./th-tshyn.nix { };
}
