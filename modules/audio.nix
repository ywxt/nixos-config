{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    # No `jack.enable` — deprecated for global LD_LIBRARY_PATH impurity.
    # Run JACK-needing apps through the `pw-jack` wrapper if ever needed.
    wireplumber.enable = true;
  };
}
