Source kernel for Samsung Tab S9 (X710/gts9wifi) build instructions

This guide is made for NixOS-based linux distros.

[Download](https://github.com/jeeneo/android_kernel_samsung_gts9wifi/releases/tag/toolchain) `SM-X710_EUR_15_Opensource.zip` then extract.

Copy the contents of this `docs` folder to the root of the newly extracted dir (next to `build_kernel_GKI.sh`)

[Download](https://github.com/jeeneo/android_kernel_samsung_gts9wifi/releases/tag/toolchain) then combine the split toolchain then extract:
`cat toolchain_X710.tar.gz.partaa toolchain_X710.tar.gz.partab > toolchain_X710.tar.gz`
`tar -toolchain_X710.tar.gz` from inside `kernel_platform`, it should extract to `prebuilts/`

Delete the `kernel_platform/common` and clone this repo with `--recurse-submodules` (for KernelSU) in it's place. (I'm currently too lazy to make a monorepo for everything, that might change in the future but is currently how I want to publish changes)

Run `nix-shell` from the projects root.

Then `./build.sh`

A `boot.img` (and etc) should be under `out/msm-kalama-kalama-gki/dist`

If you run into problems, the last build's output will be logged to `buildlog.log`, rerun with `export KBUILD_VERBOSE=1` for verbose logging (only if needed)

Please research your own errors before asking for help. For suggestions, improvments or contact info, you can file an [issue](https://github.com/jeeneo/android_kernel_samsung_gts9wifi/issues).
