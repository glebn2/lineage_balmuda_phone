#!/bin/bash
# Build LineageOS for BALMUDA Phone. Run from the source root; extra arguments go to m, e.g.
# "target-files-package otatools" before sign_release.sh.
set -eo pipefail
TOP=${ANDROID_BUILD_TOP:-$PWD}
cd "$TOP"
[ -d device/balmuda/A101BM ] || { echo "device/balmuda/A101BM not found, run from the source root"; exit 1; }
[ -f vendor/balmuda/A101BM/A101BM-vendor.mk ] || { echo "vendor/balmuda/A101BM not found"; exit 1; }
device/balmuda/A101BM/patches/apply-patches.sh "$TOP"
export LC_ALL=C
source build/envsetup.sh
lunch lineage_A101BM-cp2a-userdebug
m "$@"
