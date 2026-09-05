{
  lib,
  writeShellApplication,
  docker,
  coreutils,
}:

writeShellApplication {
  name = "ohos-build-env";

  runtimeInputs = [
    docker
    coreutils
  ];

  text = ''
        standard_context=${../docker/ohos-standard}
        standard_image=localhost/ohos-standard-dev:7.0

        usage() {
          cat <<'EOF'
    Usage: ohos-build-env TYPE [SOURCE_DIR] [COMMAND...]
           ohos-build-env --pull TYPE
           ohos-build-env --prepare standard

    TYPE is one of: standard, small, mini
    SOURCE_DIR defaults to the current directory and is mounted at
    /home/openharmony. With no COMMAND, an interactive shell is started using the
    image's default command.

    Examples:
      ohos-build-env --prepare standard
      ohos-build-env standard ~/src/openharmony
      ohos-build-env standard . ./build.sh --product-name rk3568 --ccache
      ohos-build-env small . python3 build.py -p qemu_small_system_demo@ohemu
    EOF
        }

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
            echo "ohos-build-env: preparing the OpenHarmony 7.0 standard image" >&2
            docker build --tag "$image" "$standard_context"
          fi
        else
          image=$upstream_image
          if [[ $action == pull ]]; then
            exec docker pull "$image"
          elif [[ $action == prepare ]]; then
            echo "ohos-build-env: --prepare is only needed for the standard image" >&2
            exit 2
          fi
        fi

        source_dir=''${1:-$PWD}
        if [[ $# -gt 0 ]]; then
          shift
        fi
        if [[ ! -d $source_dir ]]; then
          echo "ohos-build-env: source directory does not exist: $source_dir" >&2
          exit 2
        fi
        source_dir=$(realpath "$source_dir")

        tty_args=()
        if [[ -t 0 && -t 1 ]]; then
          tty_args=(-it)
        fi

        exec docker run --rm "''${tty_args[@]}" \
          --volume "$source_dir:/home/openharmony" \
          --workdir /home/openharmony \
          "$image" "$@"
  '';

  meta = {
    description = "Run OpenHarmony device-system source builds in Docker";
    homepage = "https://gitee.com/openharmony/docs/blob/master/zh-cn/device-dev/get-code/gettools-acquire.md";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ohos-build-env";
  };
}
