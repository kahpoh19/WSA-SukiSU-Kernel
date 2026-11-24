#!/usr/bin/env bash
# 把 LSPosed/WSA-Addon 的 gapps / cust 镜像转成 KernelSU/SukiSU 可刷入的模块 zip
# 依赖: curl erofs-utils zip   (Debian: sudo apt install curl erofs-utils zip)
set -e
ARCH=${1:-x86_64}            # x86_64 或 arm64
URL=https://github.com/LSPosed/WSA-Addon/releases/latest/download
W=$(mktemp -d); OUT=$PWD
curl -fL -o "$W/gapps.img" "$URL/gapps-13.0-$ARCH.img"
curl -fL -o "$W/cust.img"  "$URL/cust.img"
for m in gapps cust; do
  fsck.erofs --extract="$W/$m" "$W/$m.img" >/dev/null
  d="$W/out_$m"; mkdir -p "$d/system"
  cp -a "$W/$m/module.prop" "$d/"
  cp -a "$W/$m/system/." "$d/system/" 2>/dev/null || true
  for p in system_ext vendor product; do [ -d "$W/$m/$p" ] && cp -a "$W/$m/$p" "$d/system/$p"; done
  printf '%s\n' 'set_perm_recursive "$MODPATH" 0 0 0755 0644' > "$d/customize.sh"
  find "$d" -type d -empty -delete
done
cat > "$W/out_gapps/post-fs-data.sh" <<'PFS'
#!/system/bin/sh
RP=resetprop; command -v resetprop >/dev/null 2>&1 || RP=/data/adb/ksu/bin/resetprop
$RP -n ro.build.fingerprint "google/$(getprop ro.product.name)/$(getprop ro.product.device):$(getprop ro.build.version.release)/$(getprop ro.build.id)/$(getprop ro.build.version.incremental):$(getprop ro.build.type)/$(getprop ro.build.tags)"
PFS
for m in gapps cust; do (cd "$W/out_$m" && zip -q -r -9 "$OUT/lsp_$m-ksu.zip" .); done
rm -rf "$W"; ls -lh "$OUT"/lsp_*-ksu.zip
