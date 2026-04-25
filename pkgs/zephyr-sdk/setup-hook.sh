addZephyrSDKCEnvVars() {
	export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
	export ZEPHYR_SDK_INSTALL_DIR=@out@
}

addEnvHooks "$hostOffset" addZephyrSDKCEnvVars
