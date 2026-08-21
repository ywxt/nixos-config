{ lib, pkgs, ... }:

{
  options.desktop.monitors = lib.mkOption {
    description = "Monitor configuration shared with the user's compositor configuration.";
    default = [ ];
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          name = lib.mkOption {
            description = "Niri output name, as reported by `niri msg outputs`.";
            type = lib.types.str;
          };
          mode = lib.mkOption {
            description = "Output mode in WIDTHxHEIGHT or WIDTHxHEIGHT@REFRESH format.";
            type = lib.types.nullOr lib.types.str;
            default = null;
          };
          scale = lib.mkOption {
            description = "Logical scale factor for the output.";
            type = lib.types.either lib.types.int lib.types.float;
            default = 1;
          };
          transform = lib.mkOption {
            description = "Output rotation or flip transform.";
            type = lib.types.enum [
              "normal"
              "90"
              "180"
              "270"
              "flipped"
              "flipped-90"
              "flipped-180"
              "flipped-270"
            ];
            default = "normal";
          };
          position = lib.mkOption {
            description = "Output position in the global logical coordinate space.";
            default = null;
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  x = lib.mkOption { type = lib.types.int; };
                  y = lib.mkOption { type = lib.types.int; };
                };
              }
            );
          };
          enabled = lib.mkOption {
            description = "Whether the output is enabled.";
            type = lib.types.bool;
            default = true;
          };
        };
      }
    );
  };

  config.environment.systemPackages = [ pkgs.ddcutil ];
}
