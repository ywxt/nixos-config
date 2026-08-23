{
  inputs,
  pkgs,
  ...
}:

let
  noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  validatedConfig = pkgs.runCommand "noctalia-config.toml" { nativeBuildInputs = [ noctalia ]; } ''
    noctalia config validate ${./noctalia/config.toml}
    cp ${./noctalia/config.toml} $out
  '';
in
{
  packages = [ noctalia ];
  xdg.config.files."noctalia/config.toml" = {
    clobber = true;
    source = validatedConfig;
  };
}
