{ pkgs, ... }:

let
  spaceNavToggle = pkgs.writeShellScriptBin "space-nav-toggle" ''
    exec 3<>/dev/tcp/127.0.0.1/6667 || exit 1
    printf '{"RequestCurrentLayerName":{}}\n' >&3
    IFS= read -r -t 2 resp <&3 || resp=
    case "$resp" in
      *dualrole*) target=plain ;;
      *) target=dualrole ;;
    esac
    printf '{"ChangeLayer":{"new":"%s"}}\n' "$target" >&3
    exec 3<&- 3>&-
  '';
in
{
  services.kanata = {
    enable = true;
    keyboards.space-nav = {
      port = 6667;
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        (defsrc
          spc
          h j k l
          u i o n)

        (deflayer dualrole
          (tap-hold 150 150 spc (layer-while-held nav))
          h j k l
          u i o n)

        (deflayer nav
          _
          left down up right
          home bks end del)

        (deflayer plain
          spc
          h j k l
          u i o n)
      '';
    };
  };

  environment.systemPackages = [ spaceNavToggle ];
}
