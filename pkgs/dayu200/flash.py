#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only

"""Flash OpenHarmony images to a HiHope DAYU200 using rkdeveloptool."""

from __future__ import annotations

import getopt
from pathlib import Path
import re
import subprocess
import sys
import time


DEFAULT_PARTITIONS = {
    "uboot": "uboot.img",
    "trust": "trust.img",
    "boot_linux": "boot_linux.img",
    "system": "system.img",
    "vendor": "vendor.img",
    "userdata": "userdata.img",
    "resource": "resource.img",
    "ramdisk": "ramdisk.img",
}

IMAGE_SUFFIXES = (".bin", ".img", ".txt")


def usage(program: str) -> None:
    print(
        f"""Usage: {program} [OPTIONS]

Options:
  -h, --help              Print this help
  -q, --query             Query the Rockchip USB mode
  -u, --uboot             Flash uboot and trust
  -k, --kernel            Flash boot_linux
  -s, --system            Flash system
  -v, --vendor            Flash vendor
  -d, --userdata          Flash userdata
  -r, --resource          Flash resource
  -m, --ramdisk           Flash ramdisk
  -a, --all               Flash all images
  -i, --image DIR         Use images from DIR
      --dry-run           Validate and print commands without running them
"""
    )


def run(*args: str, capture: bool = False, dry_run: bool = False) -> str:
    command = ["rkdeveloptool", *args]
    print("+", " ".join(command), file=sys.stderr)
    if dry_run:
        return ""
    result = subprocess.run(
        command,
        check=True,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.STDOUT if capture else None,
    )
    return result.stdout or ""


def device_mode(*, quiet: bool = False) -> str:
    output = run("ld", capture=True)
    devices = [line for line in output.splitlines() if "Vid=0x2207" in line]
    if len(devices) != 1:
        if not quiet:
            print(output, end="")
        if not devices:
            raise RuntimeError("no Rockchip USB device found")
        raise RuntimeError(f"expected one Rockchip USB device, found {len(devices)}")

    line = devices[0]
    if "Maskrom" in line:
        return "maskrom"
    if "Loader" in line:
        return "loader"
    raise RuntimeError(f"unknown Rockchip USB mode: {line}")


def wait_for_loader(timeout: float = 15.0) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            if device_mode(quiet=True) == "loader":
                return
        except (RuntimeError, subprocess.CalledProcessError):
            pass
        time.sleep(0.5)
    raise RuntimeError("device did not re-enumerate in Loader mode")


def normalize_name(name: str) -> str:
    return name.strip().lower().replace(" ", "_")


def comparable_name(name: str) -> str:
    return re.sub(r"[^a-z0-9]", "", name.lower())


def cfg_image_path(image_dir: Path, configured_path: str) -> Path:
    # RKDevTool cfg files contain Windows paths relative to RKDevTool itself.
    # OpenHarmony places the cfg and all referenced images in the same output
    # directory, so only the configured basename is relevant here.
    filename = configured_path.replace("\\", "/").rsplit("/", 1)[-1]
    return image_dir / filename


def load_cfg(image_dir: Path) -> dict[str, Path] | None:
    cfg_path = image_dir / "config.cfg"
    if not cfg_path.is_file():
        return None

    data = cfg_path.read_bytes()
    strings = [
        match.group().decode("utf-16le")
        for match in re.finditer(rb"(?:[\x20-\x7e]\x00){2,}", data)
    ]
    images: dict[str, Path] = {}
    previous_image = -1
    for index, configured_path in enumerate(strings):
        if not configured_path.lower().endswith(IMAGE_SUFFIXES):
            continue

        path = cfg_image_path(image_dir, configured_path)
        stem = path.stem.lower()
        if stem == "miniloaderall":
            name = "loader"
        elif stem == "parameter":
            name = "parameter"
        else:
            name = ""
            for label in reversed(strings[previous_image + 1 : index]):
                if comparable_name(label) == comparable_name(stem):
                    name = normalize_name(label)
                    break
            if not name:
                previous_image = index
                continue

        images[name] = path
        previous_image = index

    if "parameter" not in images:
        raise RuntimeError(f"cannot read a Parameter entry from {cfg_path}")
    if not any(name not in ("loader", "parameter") for name in images):
        raise RuntimeError(f"cannot read partition images from {cfg_path}")

    print(f"Using image configuration: {cfg_path}", file=sys.stderr)
    return images


def main(argv: list[str]) -> int:
    try:
        options, extra = getopt.getopt(
            argv,
            "hquksvdrmai:",
            [
                "help",
                "query",
                "uboot",
                "kernel",
                "system",
                "vendor",
                "userdata",
                "resource",
                "ramdisk",
                "all",
                "image=",
                "dry-run",
            ],
        )
    except getopt.GetoptError as error:
        print(error, file=sys.stderr)
        usage(Path(sys.argv[0]).name)
        return 2

    if extra:
        print(f"unexpected arguments: {' '.join(extra)}", file=sys.stderr)
        return 2
    if not options:
        usage(Path(sys.argv[0]).name)
        return 0

    flags = {option for option, _ in options}
    if "-h" in flags or "--help" in flags:
        usage(Path(sys.argv[0]).name)
        return 0
    if "-q" in flags or "--query" in flags:
        print(device_mode())
        return 0

    image_dir = Path.cwd() / "out/ohos-arm-release/packages/phone/images"
    for option, value in options:
        if option in ("-i", "--image"):
            image_dir = Path(value)
    image_dir = image_dir.expanduser().resolve()
    dry_run = "--dry-run" in flags

    cfg_images = load_cfg(image_dir)
    partition_images = (
        {
            name: path
            for name, path in cfg_images.items()
            if name not in ("loader", "parameter")
        }
        if cfg_images is not None
        else {name: image_dir / filename for name, filename in DEFAULT_PARTITIONS.items()}
    )

    selected: list[str] = []
    if "-a" in flags or "--all" in flags:
        selected = list(partition_images)
    else:
        choices = [
            (("-u", "--uboot"), ("uboot", "trust")),
            (("-k", "--kernel"), ("boot_linux",)),
            (("-s", "--system"), ("system",)),
            (("-v", "--vendor"), ("vendor",)),
            (("-d", "--userdata"), ("userdata",)),
            (("-r", "--resource"), ("resource",)),
            (("-m", "--ramdisk"), ("ramdisk",)),
        ]
        for option_names, partitions in choices:
            if any(option in flags for option in option_names):
                selected.extend(name for name in partitions if name in partition_images)

    if not selected:
        raise RuntimeError("no partitions selected")

    parameter = (
        cfg_images["parameter"]
        if cfg_images is not None
        else image_dir / "parameter.txt"
    )
    loader = (
        cfg_images.get("loader")
        if cfg_images is not None
        else image_dir / "MiniLoaderAll.bin"
    )
    required = [parameter]
    required.extend(partition_images[name] for name in selected)
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise RuntimeError("missing image files:\n  " + "\n  ".join(missing))

    if dry_run:
        if loader is not None and loader.is_file():
            run("db", str(loader), dry_run=True)
    else:
        mode = device_mode()
        if mode == "maskrom":
            if loader is None or not loader.is_file():
                raise RuntimeError(f"missing loader: {loader}")
            run("db", str(loader))
            wait_for_loader()

    run("prm", str(parameter), dry_run=dry_run)
    for name in selected:
        run("wlx", name, str(partition_images[name]), dry_run=dry_run)
    run("rd", dry_run=dry_run)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f"dayu200-flash: {error}", file=sys.stderr)
        raise SystemExit(1)
