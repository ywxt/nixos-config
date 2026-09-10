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
           ohos xts build [SOURCE_DIR] [PRODUCT] [SUITE] [TARGET]
           ohos xts run [SOURCE_DIR] [PRODUCT] [SUITE] [XTS_OPTIONS...]
           ohos dt run [SOURCE_DIR] [PRODUCT] [DEVTEST_OPTIONS...]
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
      ohos xts build . rk3568 acts
      ohos xts build . rk3568 acts \
        test/xts/acts/powermgr/power_manager:powermgr_power_test
      OHOS_USB_DEVICE=/dev/bus/usb/001/007 \
        ohos xts run . rk3568 acts -l ActsPowerMgrPowerTest -sn SERIAL
      OHOS_USB_DEVICE=/dev/bus/usb/001/007 \
        ohos dt run . rk3568 -t UT -ts base_object_test
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

        mode="command"
        case ''${1:-} in
          standard|small|mini) system_type=$1 ;;
          xts)
            mode=xts
            system_type=standard
            ;;
          dt|developer-test)
            mode=developer-test
            system_type=standard
            ;;
          -h|--help) usage; exit 0 ;;
          *) usage >&2; exit 2 ;;
        esac
        shift

        if [[ $mode == xts ]]; then
          case ''${1:-} in
            build|run) xts_action=$1 ;;
            *)
              echo "ohos: xts action must be 'build' or 'run'" >&2
              usage >&2
              exit 2
              ;;
          esac
          shift
        fi

        if [[ $mode == developer-test ]]; then
          case ''${1:-} in
            run) ;;
            *)
              echo "ohos: dt action must be 'run'" >&2
              usage >&2
              exit 2
              ;;
          esac
          shift
        fi

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

        container_command=("$@")
        if [[ $mode == xts ]]; then
          product=''${1:-rk3568}
          if [[ $# -gt 0 ]]; then
            shift
          fi
          suite=''${1:-acts}
          if [[ $# -gt 0 ]]; then
            shift
          fi

          if [[ $xts_action == build ]]; then
            target=''${1:-}
            if [[ $# -gt 0 ]]; then
              shift
            fi
            if [[ $# -gt 0 ]]; then
              echo "ohos: unexpected XTS build arguments: $*" >&2
              exit 2
            fi
            # Use the suite's official entry point; it sets XTS_SUITENAME and
            # the remaining suite-specific build arguments itself.
            # shellcheck disable=SC2016
            container_command=(
              bash -lc '
                product=$1
                suite=$2
                target=$3
                target=''${target#//}
                suite_build=/home/openharmony/test/xts/$suite/build.sh
                if [[ ! -x $suite_build ]]; then
                  echo "ohos: unsupported XTS suite or missing build script: $suite" >&2
                  exit 2
                fi
                product_config=$(find /home/openharmony/vendor -mindepth 2 -maxdepth 3 \
                  -path "*/$product/config.json" -print -quit)
                if [[ -z $product_config ]]; then
                  echo "ohos: product configuration not found: $product" >&2
                  exit 2
                fi
                target_arch=$(sed -n "s/.*\"target_cpu\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" \
                  "$product_config" | head -n 1)
                if [[ -z $target_arch ]]; then
                  echo "ohos: target_cpu not found in: $product_config" >&2
                  exit 2
                fi
                python_dir=/home/openharmony/prebuilts/python/linux-x86/current/bin
                if [[ ! -x $python_dir/python3 ]]; then
                  echo "ohos: OpenHarmony Python toolchain not found: $python_dir" >&2
                  exit 2
                fi
                export PATH=$python_dir:$PATH
                build_args=("product_name=$product" "target_arch=$target_arch")
                if [[ -n $target ]]; then
                  build_args+=("suite=$target")
                fi
                exec "$suite_build" "''${build_args[@]}"
              ' ohos-xts-build "$product" "$suite" "$target"
            )
          else
            # This script is intentionally expanded by the container's bash.
            # shellcheck disable=SC2016
            container_command=(
              bash -lc '
                product=$1
                suite=$2
                shift 2
                build_prop=/home/openharmony/out/preloader/$product/build.prop
                device_name=
                if [[ -f $build_prop ]]; then
                  device_name=$(sed -n "s/^device_name=//p" "$build_prop" | head -n 1)
                fi
                out_name=''${device_name:-$product}
                suite_dir=/home/openharmony/out/$out_name/suites/$suite/$suite
                if [[ ! -f $suite_dir/run.sh ]]; then
                  echo "ohos: XTS runner not found: $suite_dir/run.sh" >&2
                  echo "ohos: build it first with: ohos xts build . $product $suite" >&2
                  exit 1
                fi
                for toolchains in /home/openharmony/prebuilts/ohos-sdk/linux/*/toolchains; do
                  if [[ -d $toolchains ]]; then
                    PATH=$toolchains:$PATH
                  fi
                done
                export PATH
                cd "$suite_dir"
                exec bash run.sh run "$suite" "$@"
              ' ohos-xts "$product" "$suite" "$@"
            )
          fi
        fi

        if [[ $mode == developer-test ]]; then
          product=''${1:-rk3568}
          if [[ $# -gt 0 ]]; then
            shift
          fi
          developer_test=/home/openharmony/test/testfwk/developer_test/start.sh
          # Keep the framework's official entry point and argument parser.
          # This script is intentionally expanded by the container's bash.
          # shellcheck disable=SC2016
          container_command=(
            bash -lc '
              developer_test=$1
              product=$2
              shift 2
              if [[ ! -x $developer_test ]]; then
                echo "ohos: Developer Test entry point not found: $developer_test" >&2
                exit 2
              fi
              exec "$developer_test" run -p "$product" "$@"
            ' ohos-developer-test "$developer_test" "$product" "$@"
          )
        fi

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
          "$image" "''${container_command[@]}"
  '';

  meta = {
    description = "Run OpenHarmony device-system source builds in Docker";
    homepage = "https://gitee.com/openharmony/docs/blob/master/zh-cn/device-dev/get-code/gettools-acquire.md";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ohos";
  };
}
