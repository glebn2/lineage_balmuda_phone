# LineageOS 24.0 for BALMUDA Phone (unofficial)

Unofficial LineageOS 24.0 (Android 17) for BALMUDA Phone. One image for A101BM and X01A; the device
codename is `A101BM`.

Builds, TWRP and discussion (Russian): [4PDA thread](https://4pda.to/forum/index.php?showtopic=1068017),
[downloads](https://4pda.to/forum/index.php?showtopic=1068017&view=findpost&p=145680258).

## Repositories

| Path | Repository |
|---|---|
| `device/balmuda/A101BM` | [android_device_balmuda_A101BM](https://github.com/glebn2/android_device_balmuda_A101BM) |
| `vendor/balmuda` | [proprietary_vendor_balmuda](https://github.com/glebn2/proprietary_vendor_balmuda) |
| `kernel/balmuda/A101BM` | [LineageOS/android_kernel_motorola_sm7250](https://github.com/LineageOS/android_kernel_motorola_sm7250), UAPI headers only |

This repository has the local manifest, build and signing scripts, and the TWRP installer.
TWRP for BALMUDA Phone: [twrp_device_balmuda_A101BM](https://github.com/glebn2/twrp_device_balmuda_A101BM).

## Build

Set up the build environment as described in the LineageOS wiki, then:

```bash
git clone https://github.com/glebn2/lineage_balmuda_phone ~/lineage_balmuda_phone
mkdir -p ~/lineage && cd ~/lineage
repo init -u https://github.com/LineageOS/android.git -b lineage-24.0 --git-lfs --no-clone-bundle
mkdir -p .repo/local_manifests
cp ~/lineage_balmuda_phone/local_manifests/balmuda_phone.xml .repo/local_manifests/
repo sync -c --no-tags
~/lineage_balmuda_phone/scripts/build.sh
```

`build.sh` applies `device/balmuda/A101BM/patches` first. Revert them before `repo sync`:

```bash
device/balmuda/A101BM/patches/apply-patches.sh --revert
```

TWRP zip from a test-key build:

```bash
ANDROID_BUILD_TOP=~/lineage python3 ~/lineage_balmuda_phone/twrp-zip/build_lineage_zip.py \
  24.0-$(date +%Y%m%d)-UNOFFICIAL lineage-BALMUDA_Phone-TWRP.zip ~/lineage/out/target/product/A101BM
```

Signed release:

```bash
~/lineage_balmuda_phone/scripts/build.sh target-files-package otatools
~/lineage_balmuda_phone/scripts/sign_release.sh 24.0-$(date +%Y%m%d) ~/lineage-release
```

## Notes

- Stock Kyocera 4.19 kernel, DTB, DTBO and modules. The patches make the BPF and kernel version
  checks of Android 17 non-fatal on 4.19.
- The boot image keeps the stock header version (11.0.0 / 2023-09) so TWRP can decrypt `/data`.
- SELinux is permissive; vbmeta verification is disabled.
- Install from TWRP; the zip writes the active slot.

## License

Apache-2.0. `gps/` in the device tree keeps its own license headers. Proprietary files belong to
their respective owners.
