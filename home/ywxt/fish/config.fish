if status is-interactive
  # Syntax highlighting. Use named colors so the terminal theme can decide
  # their exact shades while keeping commands and arguments distinguishable.
  set -g fish_color_normal normal
  set -g fish_color_command green --bold
  set -g fish_color_keyword magenta
  set -g fish_color_quote yellow
  set -g fish_color_redirection cyan
  set -g fish_color_end green
  set -g fish_color_error red --bold
  set -g fish_color_param white
  set -g fish_color_option cyan
  set -g fish_color_comment brblack
  set -g fish_color_selection black --background=brcyan
  set -g fish_color_search_match black --background=yellow
  set -g fish_color_operator cyan
  set -g fish_color_escape magenta
  set -g fish_color_autosuggestion brblack
  set -g fish_color_cancel red
  set -g fish_color_valid_path --underline

  alias ll 'ls -alh'
  alias rebuild 'sudo nixos-rebuild switch --flake $HOME/nixos-config#(hostname)'
  alias update 'nix flake update --flake $HOME/nixos-config'

  # Initialize a local flake template with `nfi <template>`; default to Rust.
  function nfi --argument-names template
    if test -z "$template"
      set template rust
    end
    nix flake init -t "path:$HOME/nixos-config#$template"
  end

  starship init fish | source
  direnv hook fish | source
end
