# pkgs/zephyr-sdk/default.nix

{
  lib,
  stdenvNoCC,
  fetchurl,
  bash,
  python3,
  which,
  autoPatchelfHook,
  ncurses,
  python312,
  gnuToolchains ? [ ],
  enableLlvm ? false,
  sdkVersion ? "1.0.1",
}:
let
  system = stdenvNoCC.hostPlatform.system;
  isLinux = stdenvNoCC.hostPlatform.isLinux;

  manifest = import ./toolchains.nix { inherit lib; };
  hostStr = manifest.hostStrings.${system} or (throw "zephyr-sdk: unsupported system '${system}'");

  versionMeta =
    manifest.versions.${sdkVersion}
      or (throw "zephyr-sdk: unknown version '${sdkVersion}'. Add it to pkgs/zephyr-sdk/toolchains.nix.");

  versionGnuTargets = manifest.gnuTargetsForVersion sdkVersion;

  resolvedGnuTargets =
    if gnuToolchains == "all" then
      versionGnuTargets
    else
      map (
        t:
        if lib.elem t versionGnuTargets then
          t
        else
          throw "zephyr-sdk: unknown GNU toolchain target '${t}' for v${sdkVersion}. Valid targets: ${lib.concatStringsSep ", " versionGnuTargets}"
      ) gnuToolchains;

  sha256sumDrv = fetchurl {
    url = manifest.sha256sumUrl sdkVersion;
    hash = versionMeta.sha256sumHash;
  };

  hashTable = manifest.parseHashFile (builtins.readFile sha256sumDrv);

  getHash =
    filename:
    hashTable.${filename}
      or (throw "zephyr-sdk: '${filename}' not found in sha256.sum for v${sdkVersion}");

  bundleTarball = fetchurl {
    url = manifest.bundleUrl {
      version = sdkVersion;
      inherit hostStr;
    };
    sha256 = getHash "zephyr-sdk-${sdkVersion}_${hostStr}_minimal.tar.xz";
  };

  gnuToolchainTarballs = lib.genAttrs resolvedGnuTargets (
    target:
    let
      filename = "toolchain_gnu_${hostStr}_${target}.tar.xz";
    in
    fetchurl {
      url = manifest.gnuUrl {
        version = sdkVersion;
        inherit hostStr target;
      };
      sha256 = getHash filename;
    }
  );

  llvmTarball = fetchurl {
    url = manifest.llvmUrl {
      version = sdkVersion;
      inherit hostStr;
    };
    sha256 = getHash "toolchain_llvm_${hostStr}.tar.xz";
  };

in
stdenvNoCC.mkDerivation {
  pname = "zephyr-sdk";
  version = sdkVersion;

  src = bundleTarball;

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  # ------------------------------------------------------------------ #
  #  Build inputs                                                        #
  # ------------------------------------------------------------------ #

  nativeBuildInputs = [
    bash
    python3
    which
  ]
  ++ lib.optionals isLinux [
    autoPatchelfHook
  ];

  buildInputs = lib.optionals isLinux [
    ncurses
    python312
  ];

  # ------------------------------------------------------------------ #
  #  postUnpack                                                          #
  # ------------------------------------------------------------------ #

  postUnpack = ''
    rm -f "$sourceRoot/setup.sh"
    ${lib.optionalString isLinux ''
      installer=$(ls "$sourceRoot/hosttools/zephyr-sdk-"*"-hosttools-standalone-"*".sh" 2>/dev/null | head -n1)
      if [ -z "$installer" ]; then
        echo "WARNING: hosttools installer not found — skipping."
      else
        chmod +x "$installer"
        bash "$installer" -y -p -d "$sourceRoot/hosttools"
        rm -f "$installer"
      fi
    ''}

    mkdir -p "$sourceRoot/gnu"
    ${lib.concatMapStrings (target: ''
      tar -xf ${gnuToolchainTarballs.${target}} -C "$sourceRoot/gnu/"
    '') resolvedGnuTargets}

    ${lib.optionalString enableLlvm ''
      tar -xf ${llvmTarball} -C "$sourceRoot/"
    ''}
  '';

  # ------------------------------------------------------------------ #
  #  installPhase                                                        #
  # ------------------------------------------------------------------ #

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r . "$out/zephyr-sdk-${sdkVersion}"

    patchShebangs "$out/zephyr-sdk-${sdkVersion}"

    ${lib.optionalString isLinux ''
      mkdir -p "$out/lib/udev/rules.d"
      cp "$out/zephyr-sdk-${sdkVersion}/hosttools/sysroots/"*"-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules" \
        "$out/lib/udev/rules.d/"
    ''}

    runHook postInstall
  '';

  setupHook = ./setup-hook.sh;

  meta = with lib; {
    description = "Zephyr RTOS toolchain SDK";
    homepage = "https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html";
    license = licenses.asl20;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    maintainers = [ ];
  };
}
