{ pkgs, ... }:

{
  /*
    iPhone / iPad support over USB (usbmuxd + libimobiledevice).

    Pair the device (unlock it first and tap "Trust" when prompted):

      idevicepair pair

    Useful commands:

      idevice_id -l            list connected devices
      ideviceinfo              query device information
      idevicebackup2 backup --full ~/backups/iphone
      idevicesyslog            stream device syslog
      idevicescreenshot shot.png
      iproxy 2222:22           forward localhost:2222 to device port 22
      afcclient                browse /var/mobile/Media over AFC

    Mount the media partition (photos are under DCIM/):

      mkdir -p ~/iphone
      ifuse ~/iphone
      fusermount3 -u ~/iphone
  */
  services.usbmuxd.enable = true;

  environment.systemPackages = [
    pkgs.libimobiledevice # idevice* tools, afcclient
    pkgs.libusbmuxd # iproxy
    pkgs.ifuse # FUSE mount of the media partition
  ];
}
