{ inputs, pkgs, ... }:

let
  editSecrets = pkgs.writeShellApplication {
    name = "sops-secrets";
    runtimeInputs = [ pkgs.findutils ];
    text = ''
      if (( $# > 1 )); then
        echo "Usage: sops-secrets [FILE|DIRECTORY]" >&2
        exit 2
      fi

      config_directory="''${NIXOS_CONFIG_DIR:-$HOME/nixos-config}"
      target="''${1:-$config_directory/secrets}"

      # A bare filename is looked up in the repository's secrets directory.
      if (( $# == 1 )) && [[ $target != */* && ! -e $target ]]; then
        target="$config_directory/secrets/$target"
      fi

      if [[ -d $target ]]; then
        mapfile -d "" secret_files < <(
          find "$target" -maxdepth 1 -type f \
            \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
            -print0 | sort -z
        )

        if (( ''${#secret_files[@]} == 0 )); then
          echo "sops-secrets: no secret files found in: $target" >&2
          exit 1
        elif (( ''${#secret_files[@]} == 1 )); then
          target="''${secret_files[0]}"
        else
          echo "Select a secrets file:"
          selected=""
          select selected in "''${secret_files[@]}"; do
            [[ -n $selected ]] && break
            echo "Invalid selection." >&2
          done
          [[ -n $selected ]] || exit 130
          target="$selected"
        fi
      elif [[ ! -d $(dirname "$target") ]]; then
        echo "sops-secrets: parent directory not found: $(dirname "$target")" >&2
        exit 1
      fi

      export SOPS_AGE_KEY_CMD="sudo ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key"
      exec ${pkgs.sops}/bin/sops "$target"
    '';
  };
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  environment.systemPackages = [
    pkgs.age
    pkgs.sops
    pkgs.ssh-to-age
    editSecrets
  ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
