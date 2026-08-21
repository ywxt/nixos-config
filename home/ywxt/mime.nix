{ lib, ... }:

let
  associations = desktop: types: lib.genAttrs types (_: [ desktop ]);

  firefoxTypes = [
    "application/json"
    "application/pdf"
    "application/x-xpinstall"
    "image/svg+xml"
    "image/webp"
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/mailto"
  ];

  imageTypes = [
    "image/avif"
    "image/bmp"
    "image/gif"
    "image/heif"
    "image/jpeg"
    "image/png"
    "image/tiff"
    "image/vnd.zbrush.pcx"
    "image/x-portable-anymap"
    "image/x-portable-bitmap"
    "image/x-portable-graymap"
    "image/x-portable-pixmap"
    "image/x-tga"
    "image/x-xbitmap"
  ];

  archiveTypes = [
    "application/gzip"
    "application/vnd.debian.binary-package"
    "application/vnd.efi.iso"
    "application/vnd.ms-cab-compressed"
    "application/vnd.rar"
    "application/x-7z-compressed"
    "application/x-archive"
    "application/x-arj"
    "application/x-bcpio"
    "application/x-bzip2"
    "application/x-bzip2-compressed-tar"
    "application/x-compress"
    "application/x-compressed-tar"
    "application/x-cpio"
    "application/x-cpio-compressed"
    "application/x-iso9660-appimage"
    "application/x-lha"
    "application/x-lrzip"
    "application/x-lrzip-compressed-tar"
    "application/x-lz4"
    "application/x-lz4-compressed-tar"
    "application/x-lzip"
    "application/x-lzip-compressed-tar"
    "application/x-lzma"
    "application/x-lzma-compressed-tar"
    "application/x-lzop"
    "application/x-rpm"
    "application/x-source-rpm"
    "application/x-stuffit"
    "application/x-sv4cpio"
    "application/x-sv4crc"
    "application/x-tar"
    "application/x-tarz"
    "application/x-tzo"
    "application/x-xar"
    "application/x-xz"
    "application/x-xz-compressed-tar"
    "application/x-zstd-compressed-tar"
    "application/zip"
    "application/zlib"
    "application/zstd"
  ];

  mediaTypes = [
    "application/mxf"
    "application/ogg"
    "application/ram"
    "application/sdp"
    "application/vnd.adobe.flash.movie"
    "application/vnd.apple.mpegurl"
    "application/vnd.ms-asf"
    "application/vnd.ms-wpl"
    "application/vnd.rn-realmedia"
    "application/x-matroska"
    "application/x-quicktime-media-link"
    "application/x-shorten"
    "audio/AMR"
    "audio/AMR-WB"
    "audio/aac"
    "audio/ac3"
    "audio/basic"
    "audio/flac"
    "audio/midi"
    "audio/mp2"
    "audio/mp4"
    "audio/mpeg"
    "audio/ogg"
    "audio/vnd.dts"
    "audio/vnd.dts.hd"
    "audio/vnd.rn-realaudio"
    "audio/vnd.wave"
    "audio/webm"
    "audio/x-adpcm"
    "audio/x-aiff"
    "audio/x-ape"
    "audio/x-gsm"
    "audio/x-it"
    "audio/x-matroska"
    "audio/x-mod"
    "audio/x-mpegurl"
    "audio/x-ms-asx"
    "audio/x-ms-wma"
    "audio/x-musepack"
    "audio/x-s3m"
    "audio/x-scpls"
    "audio/x-speex"
    "audio/x-tta"
    "audio/x-vorbis+ogg"
    "audio/x-wavpack"
    "audio/x-xm"
    "image/vnd.rn-realpix"
    "text/x-google-video-pointer"
    "video/3gpp"
    "video/3gpp2"
    "video/dv"
    "video/mp2t"
    "video/mp4"
    "video/mpeg"
    "video/ogg"
    "video/quicktime"
    "video/vnd.avi"
    "video/vnd.mpegurl"
    "video/vnd.rn-realvideo"
    "video/webm"
    "video/x-anim"
    "video/x-flic"
    "video/x-flv"
    "video/x-matroska"
    "video/x-ms-wmv"
    "video/x-nsv"
    "video/x-ogm+ogg"
    "video/x-theora+ogg"
    "x-content/audio-cdda"
    "x-content/audio-player"
    "x-content/video-dvd"
    "x-content/video-svcd"
    "x-content/video-vcd"
    "x-scheme-handler/icy"
    "x-scheme-handler/icyx"
    "x-scheme-handler/mms"
    "x-scheme-handler/mmsh"
    "x-scheme-handler/rtmp"
    "x-scheme-handler/rtp"
    "x-scheme-handler/rtsp"
  ];
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      associations "firefox.desktop" firefoxTypes
      // associations "imv.desktop" imageTypes
      // associations "org.kde.ark.desktop" archiveTypes
      // associations "vlc.desktop" mediaTypes
      // {
        "application/java-archive" = [ "java-java-openjdk.desktop" ];
        "application/x-code-workspace" = [ "code.desktop" ];
        "application/yaml" = [ "code.desktop" ];
        "inode/directory" = [ "thunar.desktop" ];
        "text/plain" = [ "code.desktop" ];
        "x-scheme-handler/steam" = [ "steam.desktop" ];
        "x-scheme-handler/steamlink" = [ "steam.desktop" ];
        "x-scheme-handler/tg" = [ "org.telegram.desktop.desktop" ];
        "x-scheme-handler/tonsite" = [ "org.telegram.desktop.desktop" ];
        "x-scheme-handler/vscode" = [ "code-url-handler.desktop" ];
      };
  };
}
