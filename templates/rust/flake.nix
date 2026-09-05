{
  description = "Rust development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              pkg-config
              rustup
            ];

            RUSTC_VERSION = "stable";

            shellHook = ''
              export PATH="''${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"

              if ! rustup run "$RUSTC_VERSION" rustc --version >/dev/null 2>&1 \
                || ! rustup run "$RUSTC_VERSION" cargo --version >/dev/null 2>&1; then
                rustup toolchain install "$RUSTC_VERSION" --profile default
              fi
            '';
          };
        }
      );
    };
}
