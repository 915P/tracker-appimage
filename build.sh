#!/usr/bin/env bash
#
# 从上游官方产物构建 Tracker AppImage。
#
#   上游来源（全部官方、未修改）：
#     tracker.jar          opensourcephysics.github.io（官网 archives，等价于安装包内的 jar）
#     xuggle / logback 等  github.com/OpenSourcePhysics/tracker 的 version_<ver> tag
#     appimagetool/runtime github.com/AppImage/*
#
# 用法:  ./build.sh            # 默认 TRACKER_VERSION=6.3.5
#        TRACKER_VERSION=6.3.4 ./build.sh
#
set -euo pipefail

VERSION="${TRACKER_VERSION:-6.3.5}"
ARCH="${ARCH:-x86_64}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
CACHE="$ROOT/build/cache"
APPDIR="$ROOT/build/AppDir"
OUT="$ROOT/Tracker-${VERSION}-${ARCH}.AppImage"

TRACKER_JAR_URL="https://opensourcephysics.github.io/tracker-website/archives/tracker-${VERSION}.jar"
LIBS_BASE="https://github.com/OpenSourcePhysics/tracker/raw/refs/tags/version_${VERSION}/libraries"
LIBS=(xuggle-xuggler-server-all.jar logback-classic.jar logback-core.jar slf4j-api.jar)
APPIMAGETOOL_URL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-${ARCH}.AppImage"
RUNTIME_URL="https://github.com/AppImage/type2-runtime/releases/download/continuous/runtime-${ARCH}"

command -v curl >/dev/null || { echo "需要 curl"; exit 1; }
command -v unzip >/dev/null || { echo "需要 unzip"; exit 1; }
mkdir -p "$CACHE"

fetch() { # <url> <dest>
    local url="$1" dest="$2"
    if [ -s "$dest" ]; then
        echo "  = $(basename "$dest")（缓存）"
        return 0
    fi
    echo "  ↓ $(basename "$dest")"
    if command -v aria2c >/dev/null 2>&1; then
        # 多线程分段下载（16 连接 × 4 MB 分段），国内直连 GitHub 也能跑满带宽
        if ! aria2c -x16 -s16 -k4M \
                --max-tries=3 --retry-wait=2 \
                --console-log-level=warn --summary-interval=0 \
                --file-allocation=none \
                -d "$(dirname "$dest")" -o "$(basename "$dest")" "$url"; then
            echo "下载失败: $url" >&2
            exit 1
        fi
    else
        if ! curl -sfL --retry 3 --connect-timeout 15 --max-time 600 -o "$dest.part" "$url"; then
            echo "下载失败: $url（安装 aria2c 可多线程加速）" >&2
            rm -f "$dest.part"
            exit 1
        fi
        mv "$dest.part" "$dest"
    fi
}

echo "[1/4] 下载上游产物 -> $CACHE"
fetch "$TRACKER_JAR_URL" "$CACHE/tracker-${VERSION}.jar"
for lib in "${LIBS[@]}"; do
    fetch "$LIBS_BASE/$lib" "$CACHE/$lib"
done
fetch "$APPIMAGETOOL_URL" "$CACHE/appimagetool.AppImage"
fetch "$RUNTIME_URL" "$CACHE/runtime-${ARCH}"

# 校验 jar 是真 zip，别把 HTML 错误页打进镜像
unzip -tqq "$CACHE/tracker-${VERSION}.jar" >/dev/null || {
    echo "tracker.jar 损坏（不是有效 zip），删除 $CACHE/tracker-${VERSION}.jar 后重试" >&2
    exit 1
}

echo "[2/4] 组装 AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/lib/tracker"
cp "$CACHE/tracker-${VERSION}.jar"                 "$APPDIR/usr/lib/tracker/tracker.jar"
for lib in "${LIBS[@]}"; do
    cp "$CACHE/$lib" "$APPDIR/usr/lib/tracker/$lib"
done
cp "$ROOT/AppRun"         "$APPDIR/AppRun"
cp "$ROOT/Tracker.desktop" "$APPDIR/Tracker.desktop"
cp "$ROOT/icon.png"        "$APPDIR/tracker.png"
cp "$ROOT/icon.png"        "$APPDIR/.DirIcon"
chmod +x "$APPDIR/AppRun"

echo "[3/4] 生成 AppImage -> $OUT"
chmod +x "$CACHE/appimagetool.AppImage"
ARCH="$ARCH" \
APPIMAGE_EXTRACT_AND_RUN=1 \
"$CACHE/appimagetool.AppImage" -n \
    --runtime-file "$CACHE/runtime-${ARCH}" \
    "$APPDIR" "$OUT"

echo "[4/4] 完成"
ls -lh "$OUT"
echo
echo "运行:  chmod +x \"$OUT\" && \"$OUT\""