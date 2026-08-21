{ ... }:

{
  # Allow desktop users to configure Anne Pro 2 keyboards over USB.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8008", GROUP:="users", MODE:="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8008", GROUP:="users", MODE:="0660"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8009", GROUP:="users", MODE:="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="8009", GROUP:="users", MODE:="0660"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a292", GROUP:="users", MODE:="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a292", GROUP:="users", MODE:="0660"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a293", GROUP:="users", MODE:="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="04d9", ATTRS{idProduct}=="a293", GROUP:="users", MODE:="0660"
  '';
}
