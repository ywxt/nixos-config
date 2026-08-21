{
  description = "NixOS configuration for ywxt-ws";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
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

  outputs = inputs@{ nixpkgs, home-manager, noctalia, ... }: {
    nixosConfigurations.ywxt-ws = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/ywxt-ws
        noctalia.nixosModules.default
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            extraSpecialArgs = { inherit inputs; };
            users.ywxt = import ./home/ywxt;
          };
        }
      ];
    };
  };
}
