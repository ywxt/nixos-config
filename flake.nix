{
  description = "NixOS configurations for ywxt";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };

    rime-huma = {
      url = "github:ywxt/rime-huma";
      flake = false;
    };

    colloid-kde = {
      url = "github:vinceliuice/Colloid-kde";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      hjem,
      noctalia,
      ...
    }:
    {
      templates = {
        default = {
          path = ./templates/rust;
          description = "Rust development environment managed by rustup";
        };

        rust = {
          path = ./templates/rust;
          description = "Rust development environment managed by rustup";
        };

        frontend = {
          path = ./templates/frontend;
          description = "Frontend development environment with Node.js and pnpm";
        };

        python = {
          path = ./templates/python;
          description = "Python development environment with uv";
        };

        cpp = {
          path = ./templates/cpp;
          description = "C/C++ development environment with Clang, CMake and Ninja";
        };
      };

      nixosConfigurations.ywxt-ws = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/ywxt-ws
          hjem.nixosModules.default
          {
            hjem = {
              specialArgs = { inherit inputs; };
              users.ywxt = {
                enable = true;
                imports = [ ./home/ywxt ];
              };
            };
          }
        ];
      };

      nixosConfigurations.ywxt-work = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/ywxt-work
          hjem.nixosModules.default
          {
            hjem = {
              specialArgs = { inherit inputs; };
              users.ywxt = {
                enable = true;
                imports = [ ./home/ywxt ];
              };
            };
          }
        ];
      };
    };
}
