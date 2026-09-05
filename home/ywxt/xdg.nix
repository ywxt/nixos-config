{ config, lib, ... }:

let
  variables = {
    EDITOR = "nvim";
    XDG_CACHE_HOME = "${config.directory}/.cache";
    XDG_CONFIG_HOME = "${config.directory}/.config";
    XDG_DATA_HOME = "${config.directory}/.local/share";
    XDG_STATE_HOME = "${config.directory}/.local/state";
  };
  environmentD = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "${name}=${value}") config.environment.sessionVariables
  );
in
{
  environment.sessionVariables = variables;
  xdg.config.files."environment.d/10-home.conf" = {
    clobber = true;
    text = environmentD + "\n";
  };

  xdg = {
    cache.directory = "${config.directory}/.cache";
    config.directory = "${config.directory}/.config";
    data.directory = "${config.directory}/.local/share";
    state.directory = "${config.directory}/.local/state";
  };
}
