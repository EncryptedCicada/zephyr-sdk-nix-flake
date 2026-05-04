{ pkgs, zephyrSdk }:

pkgs.mkShell {
  name = "zephyr-dev";

  packages = with pkgs; [
    # Build system
    cmake
    ninja
    gnumake
    dtc
    gperf
    ccache

    # Host compiler and analysis tools
    clang
    clang-tools
    gdb

    # Flashing
    dfu-util

    # Zephyr tooling (using the system python for consistency)
    (python3.withPackages (
      ps: with ps; [
        west
        pyelftools
        jsonschema
      ]
    ))

    # The cross-compilers
    zephyrSdk

    # ESP
    esptool

    # Nordic
    (nrfutil.withExtensions [
      "nrfutil-device"
      "nrfutil-trace"
      "nrfutil-ble-sniffer"
    ])
    nrf-udev
    segger-jlink
  ];
}
