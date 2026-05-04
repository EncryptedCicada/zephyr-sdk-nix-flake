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

    # Devtools
    gitlint

    # Zephyr tooling (using the system python for consistency)
    (python312.withPackages (
      ps: with ps; [
        west
        pyelftools
        pyyaml
        jsonschema
        pykwalify
        canopen
        packaging
        patool
        pylink-square
        requests
        semver
        tqdm
        reuse
        anytree
        intelhex
        colorama
        ply
        gcovr
        coverage
        pytest
        mypy
        junitparser
        python-dotenv
        gitpython
        plotly
        junit2html
        lpc-checksum
        spsdk
        pillow
        pygithub
        graphviz
        pyusb
        psutil
        pyserial
        packaging
        setuptools
        lxml
        pylint
        ruff
        sphinx-lint
        tabulate
        unidiff
        vermin
        yamllint
        pyocd
        natsort
        cbor
        python-can
        spdx-tools
        opencv-python
        numpy
        python-dateutil
        docopt
        ruamel-yaml
        six
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
