#!/bin/bash
# Sign a BALMUDA Phone build with your own keys (LineageOS wiki, "Signing builds") and make the TWRP zip.
# Build first: build.sh target-files-package otatools
# Keys: $ANDROID_CERTS (default ~/.android-certs), created on first run. Keep them private: an update
# signed with other keys cannot be installed without Format Data.
# Usage (from the source root): sign_release.sh <version, e.g. 24.0-20261025> <output dir>
set -e
VER=${1:?version}
DST=${2:?output dir}
L=${ANDROID_BUILD_TOP:-$PWD}
K=${ANDROID_CERTS:-$HOME/.android-certs}
OUT=$L/out/target/product/A101BM
SUBJ=${CERT_SUBJECT:-'/C=JP/O=LineageOS BALMUDA Phone unofficial/OU=Release'}
HERE=$(cd "$(dirname "$0")" && pwd)
HB=$L/out/host/linux-x86/bin
JDK=$(ls -d $L/prebuilts/jdk/jdk21/linux-x86 2>/dev/null || ls -d $L/prebuilts/jdk/jdk*/linux-x86 | tail -1)
export PATH=$HB:$JDK/bin:$PATH
cd "$L"

mkdir -p "$K"; chmod 700 "$K"
# make_key always exits with 1, check the files instead
mk() { echo "" | "$1" "$2" "$3" >/dev/null 2>&1 || true; [ -s "$2.pk8" ] && [ -s "$2.x509.pem" ] || { echo "make_key failed: $2"; exit 1; }; }
for c in bluetooth cyngn-app media networkstack nfc platform releasekey sdk_sandbox shared testcert verity; do
  [ -e "$K/$c.pk8" ] || mk development/tools/make_key "$K/$c" "$SUBJ/CN=$c"
done
ln -sf releasekey.pk8 "$K/testkey.pk8"; ln -sf releasekey.x509.pem "$K/testkey.x509.pem"
cp -f development/tools/make_key "$K/make_key4096"; sed -i 's|2048|4096|g' "$K/make_key4096"

TF=$(ls -t $OUT/obj/PACKAGING/target_files_intermediates/*-target_files*.zip | head -1)
echo "target-files: $TF"
ARGS=()
# APEX: one RSA-4096 key per APEX (container and payload), PRESIGNED ones untouched
while read -r line; do
  name=$(echo "$line" | sed -n 's/^name="\([^"]*\)".*/\1/p')
  [ -n "$name" ] || continue
  echo "$line" | grep -q 'container_certificate="PRESIGNED"' && continue
  apex=${name%.apex}; apex=${apex%.capex}
  if [ ! -e "$K/$apex.pk8" ]; then
    mk "$K/make_key4096" "$K/$apex" "$SUBJ/CN=$apex"
    openssl pkcs8 -in "$K/$apex.pk8" -inform DER -nocrypt -out "$K/$apex.pem"
  fi
  ARGS+=(--extra_apks "$name=$K/$apex" --extra_apex_payload_key "$name=$K/$apex.pem")
done < <(unzip -p "$TF" META/apexkeys.txt)
# APKs with their own certificates get releasekey; standard keys are mapped by -d
STD='testkey|platform|shared|media|networkstack|bluetooth|nfc|sdk_sandbox|releasekey|PRESIGNED|cyngn-app'
while read -r line; do
  name=$(echo "$line" | sed -n 's/^name="\([^"]*\)".*/\1/p')
  cert=$(echo "$line" | sed -n 's/.*certificate="\([^"]*\)".*/\1/p')
  [ -n "$name" ] && [ -n "$cert" ] || continue
  base=$(basename "$cert" .x509.pem)
  echo "$base" | grep -qE "^($STD)$" && continue
  ARGS+=(--extra_apks "$name=$K/releasekey")
done < <(unzip -p "$TF" META/apkcerts.txt)

W=$(mktemp -d)
# releasetools rebuild boot.img with mkbootimg_version_args from misc_info.txt and drop the stock
# boot header version (11.0.0 / 2023-09) that TWRP needs to decrypt /data, so override it.
python3 - "$TF" $W/tf.zip <<'EOF'
import sys, zipfile
src, dst = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(src) as zi, zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED, allowZip64=True) as zo:
    for it in zi.infolist():
        data = zi.read(it.filename)
        if it.filename == "META/misc_info.txt":
            lines = [l for l in data.decode().splitlines() if not l.startswith("mkbootimg_version_args=")]
            lines.append("mkbootimg_version_args=--os_version 11.0.0 --os_patch_level 2023-09")
            data = ("\n".join(lines) + "\n").encode()
        zo.writestr(it, data)
EOF
sign_target_files_apks -o -d "$K" "${ARGS[@]}" $W/tf.zip $W/signed-target_files.zip
rm -f $W/tf.zip
img_from_target_files $W/signed-target_files.zip $W/signed-img.zip
mkdir -p "$DST" $W/img
unzip -o -q $W/signed-img.zip -d $W/img
cp $W/signed-target_files.zip "$DST/"
ANDROID_BUILD_TOP=$L python3 "$HERE/../twrp-zip/build_lineage_zip.py" \
  "$VER-UNOFFICIAL" "$DST/lineage-$VER-UNOFFICIAL-BALMUDA_Phone-TWRP.zip" $W/img
( cd "$DST" && sha256sum *.zip > SHA256SUMS.txt && cat SHA256SUMS.txt )
rm -rf $W
