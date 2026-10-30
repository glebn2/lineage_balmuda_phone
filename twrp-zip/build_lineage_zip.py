#!/usr/bin/env python3
"""Build the TWRP installer zip of LineageOS for BALMUDA Phone.

Usage: ANDROID_BUILD_TOP=<source root> build_lineage_zip.py <version> <out.zip> <image dir>
The image dir is out/target/product/A101BM or an unpacked img_from_target_files zip.
"""
import hashlib, os, subprocess, sys, tempfile, zipfile

CHUNK = 128 * 1024 * 1024
HERE = os.path.dirname(os.path.abspath(__file__))
SUPER_SIZE = 13958643712
MODEL = "BALMUDA_Phone"
ITEMS = [("system_b", "logical", "system.img"), ("system_ext_b", "logical", "system_ext.img"),
         ("product_b", "logical", "product.img"), ("vendor_b", "logical", "vendor.img"),
         ("odm_b", "logical", "odm.img"), ("boot_b", "raw", "boot.img"), ("dtbo_b", "raw", "dtbo.img"),
         ("vbmeta_system_b", "raw", "vbmeta_system.img"), ("vbmeta_b", "raw", "vbmeta.img")]

version, out, prod = sys.argv[1:4]
top = os.environ.get("ANDROID_BUILD_TOP")
assert top, "ANDROID_BUILD_TOP is not set"
# boot.img must carry the stock header version 11.0.0 / 2023-09, otherwise TWRP cannot decrypt /data
with open(os.path.join(prod, "boot.img"), "rb") as f:
    f.seek(44)
    osv = int.from_bytes(f.read(4), "little")
assert osv == 0x16000179, f"boot.img os_version 0x{osv:08x}, expected 0x16000179"

SIMG2IMG = os.path.join(top, "out/host/linux-x86/bin/simg2img")
TMPD = tempfile.mkdtemp(prefix="lineage-zip-")

def raw_image(path):
    # The installer writes images with dd, so unsparse them
    with open(path, "rb") as f:
        magic = int.from_bytes(f.read(4), "little")
    if magic != 0xED26FF3A:
        return path
    raw = os.path.join(TMPD, os.path.basename(path) + ".raw")
    subprocess.run([SIMG2IMG, path, raw], check=True)
    return raw

lines = ["# name type size sha256 chunks"]
tmp = out + ".part"
with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for sub in ("update-binary", "updater-script"):
        data = open(os.path.join(HERE, "META-INF/com/google/android", sub), "rb").read().replace(b"\r\n", b"\n")
        z.writestr("META-INF/com/google/android/" + sub, data)
    # LineageOS backuptool keeps addon.d (GApps, Magisk) on updates
    bt = os.path.join(top, "vendor/lineage/prebuilt/common/bin")
    for f in ("backuptool.sh", "backuptool.functions"):
        z.writestr(f, open(os.path.join(bt, f), "rb").read().replace(b"\r\n", b"\n"))
    z.writestr("install.prop", f"model={MODEL}\nversion={version}\nsuper_size={SUPER_SIZE}\n")
    for name, kind, fn in ITEMS:
        path = raw_image(os.path.join(prod, fn))
        size = os.path.getsize(path)
        h = hashlib.sha256()
        n = 0
        with open(path, "rb") as f:
            while True:
                data = f.read(CHUNK)
                if not data:
                    break
                h.update(data)
                z.writestr(f"{name}.{n:03d}", data)
                n += 1
        lines.append(f"{name} {kind} {size} {h.hexdigest()} {n}")
        print(lines[-1], flush=True)
    z.writestr("images.txt", "\n".join(lines) + "\n")
os.replace(tmp, out)
for f in os.listdir(TMPD):
    os.remove(os.path.join(TMPD, f))
os.rmdir(TMPD)
print("written", out)
