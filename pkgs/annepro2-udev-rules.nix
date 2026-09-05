{
  lib,
  writeTextFile,
}:

writeTextFile {
  name = "annepro2-udev-rules";
  destination = "/lib/udev/rules.d/60-annepro2.rules";
  text = ''
    # Allow desktop users to configure Anne Pro 2 keyboards over USB.
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8008", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8008", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8009", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8009", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a292", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a292", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a293", TAG+="uaccess"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a293", TAG+="uaccess"
  '';

  meta = {
    description = "udev rules for configuring Anne Pro 2 keyboards";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
