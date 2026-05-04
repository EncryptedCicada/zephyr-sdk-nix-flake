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
        # base
        west
        pyelftools
        pyyaml
        pykwalify
        jsonschema
        canopen
        packaging
        patool
        pylink-square
        pyserial
        requests
        semver
        tqdm
        reuse
        anytree
        intelhex

        # build-test
        colorama
        ply
        gcovr
        coverage
        pytest
        mypy
        junitparser
        python-dotenv

        # run-test
        pyocd
        tabulate
        natsort
        cbor
        python-can
        spdx-tools
        opencv-python
        numpy

        # extras
        # anytree # (already declared above)
        gitpython
        plotly
        # gitlint-core # imported as a nix package
        junit2html
        lpc-checksum
        # spsdk # disabled since it is not available for python 3.12
        pillow
        pygithub
        graphviz

        # compliance
        # clang-format # imported as a nix package
        # gitlint-core # (already declared above)
        # jsonschema # (already declared above)
        # junitparser # (already declared above)
        lxml
        # pykwalify # (already declared above)
        pylint
        # python-dotenv # (already declared above)
        # reuse # (already declared above)
        ruff
        sphinx-lint
        # tabulate # (already declared above)
        unidiff
        vermin
        yamllint

        # requirements-west
        # colorama # (already declared above)
        docopt
        # packaging # (already declared above)
        # pykwalify # (already declared above)
        python-dateutil
        # pyyaml # (already declared above)
        ruamel-yaml
        six

        # misc
        pyusb
        psutil
        setuptools
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
