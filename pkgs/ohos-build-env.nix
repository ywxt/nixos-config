{
  lib,
  writeShellApplication,
  docker,
  coreutils,
}:

writeShellApplication {
  name = "ohos";

  runtimeInputs = [
    docker
    coreutils
  ];

  text = ''
        standard_context=${../docker/ohos-standard}
        standard_image=localhost/ohos-standard-dev:7.0

        usage() {
          cat <<'EOF'
    Usage: ohos TYPE [SOURCE_DIR] [COMMAND...]
           ohos --pull TYPE
           ohos --prepare standard
           ohos --clean-cache

    TYPE is one of: standard, small, mini
    SOURCE_DIR defaults to the current directory and is mounted at
    /home/openharmony. The container runs with the invoking user's UID/GID so
    generated files remain writable on the host. With no COMMAND, an interactive
    shell is started using the image's default command.

    Examples:
      ohos --prepare standard
      ohos standard ~/src/openharmony
      ohos standard . ./build.sh --product-name rk3568 --ccache
      OHOS_USB_DEVICE=/dev/bus/usb/001/007 ohos standard .
      ohos small . python3 build.py -p qemu_small_system_demo@ohemu
      ohos --clean-cache

    Set OHOS_USB_DEVICE to one /dev/bus/usb/BBB/DDD character device to pass
    that device through to the container for tools such as hdc.
    EOF
        }

        container_home="''${XDG_CACHE_HOME:-$HOME/.cache}/ohos-build-env"
        if [[ ''${1:-} == --clean-cache ]]; then
          if [[ -e $container_home ]]; then
            rm -rf -- "$container_home"
            echo "ohos: removed cache: $container_home"
          else
            echo "ohos: cache is already empty: $container_home"
          fi
          exit 0
        fi

        action=run
        if [[ ''${1:-} == --pull || ''${1:-} == --prepare ]]; then
          action=''${1#--}
          shift
        fi

        case ''${1:-} in
          standard|small|mini) system_type=$1 ;;
          -h|--help) usage; exit 0 ;;
          *) usage >&2; exit 2 ;;
        esac
        shift

        upstream_image="swr.cn-south-1.myhuaweicloud.com/openharmony-docker/docker_oh_''${system_type}:3.2"
        if [[ $system_type == standard ]]; then
          image=$standard_image
          if [[ $action == pull || $action == prepare ]]; then
            exec docker build --pull --tag "$image" "$standard_context"
          fi
          if ! docker image inspect "$image" >/dev/null 2>&1; then
            echo "ohos: preparing the OpenHarmony 7.0 standard image" >&2
            docker build --tag "$image" "$standard_context"
          fi
        else
          image=$upstream_image
          if [[ $action == pull ]]; then
            exec docker pull "$image"
          elif [[ $action == prepare ]]; then
            echo "ohos: --prepare is only needed for the standard image" >&2
            exit 2
          fi
        fi

        source_dir=''${1:-$PWD}
        if [[ $# -gt 0 ]]; then
          shift
        fi
        if [[ ! -d $source_dir ]]; then
          echo "ohos: source directory does not exist: $source_dir" >&2
          exit 2
        fi
        source_dir=$(realpath "$source_dir")

        prebuilts_cache="$container_home/prebuilts-download"
        mkdir -p "$container_home" "$prebuilts_cache"

        tty_args=()
        if [[ -t 0 && -t 1 ]]; then
          tty_args=(-it)
        fi

        device_args=()
        if [[ -n ''${OHOS_USB_DEVICE:-} ]]; then
          usb_device=$(realpath -- "''${OHOS_USB_DEVICE}")
          case $usb_device in
            /dev/bus/usb/[0-9][0-9][0-9]/[0-9][0-9][0-9]) ;;
            *)
              echo "ohos: OHOS_USB_DEVICE must name one /dev/bus/usb/BBB/DDD device" >&2
              exit 2
              ;;
          esac
          if [[ ! -c $usb_device ]]; then
            echo "ohos: USB device is not a character device: $usb_device" >&2
            exit 2
          fi
          device_args=(--device "$usb_device:$usb_device")
        fi

        exec docker run --rm "''${tty_args[@]}" "''${device_args[@]}" \
          --network host \
          --user "$(id -u):$(id -g)" \
          --env HOME="$HOME" \
          --env USER="''${USER:-ohos}" \
          --env LOGNAME="''${LOGNAME:-''${USER:-ohos}}" \
          --volume /etc/passwd:/etc/passwd:ro \
          --volume /etc/group:/etc/group:ro \
          --volume "$container_home:$HOME" \
          --volume "$prebuilts_cache:/home/openharmony_prebuilts" \
          --volume "$source_dir:/home/openharmony" \
          --workdir /home/openharmony \
          "$image" "$@"
  '';

  meta = {
    description = "Run OpenHarmony device-system source builds in Docker";
    homepage = "https://gitee.com/openharmony/docs/blob/master/zh-cn/device-dev/get-code/gettools-acquire.md";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ohos";
  };
}
