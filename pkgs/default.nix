final: _prev: {
  annepro2-udev-rules = final.callPackage ./annepro2-udev-rules.nix { };
  colloid-kvantum = final.callPackage ./colloid-kvantum.nix { };
  hdc = final.callPackage ./hdc.nix { };
  dayu200-flash = final.callPackage ./dayu200 { };
  ohos-build-env = final.callPackage ./ohos-build-env.nix { };
  rime-huma = final.callPackage ./rime-huma.nix { };
}
