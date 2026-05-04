{ pkgs, zephyrSdk }:

pkgs.mkShell {
  name = "zephyr-dev";

  packages = with pkgs; [
    # Build system
    cmake
    cmake-format
    cmake-language-server
    ninja
    gnumake
    gperf
    dtc
    ccache

    # Host compiler and analysis tools
    clang
    clang-tools
    gdb
    bear

    # Parsing (required by some Zephyr subsystems)
    bison
    flex

    # Libraries
    gtest
    libffi
    libusb1
    ncurses

    # Flashing
    dfu-util

    # Zephyr tooling
    (python3.withPackages (ps: with ps; [
      west
      pyelftools
      jsonschema
    ]))
    zephyrSdk

    # ESP flashing / toolchain management
    esptool
    espup
  ];
}
