final: _prev: {
  annepro2-udev-rules = final.callPackage ./annepro2-udev-rules.nix { };
  colloid-kvantum = final.callPackage ./colloid-kvantum.nix { };
  hihope-iot = final.callPackage ./hihope-iot.nix { };
  ohos-build-env = final.callPackage ./ohos-build-env.nix { };
  ohos-sdk = final.callPackage ./ohos-sdk.nix { };
  rime-huma = final.callPackage ./rime-huma.nix { };
}
