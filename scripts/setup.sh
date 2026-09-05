#!/bin/bash
#
# scripts/setup.sh — 新机器一键准备
#
# 做三件事：
#   1. 下载 Kokoro 朗读模型到 BundledModels/（约 90 MB）
#   2. 下载 Stable Diffusion 画图模型到 BundledStableDiffusion/（约 860 MB）
#   3. 解析 Swift Package 依赖
#
# 两个模型目录都在 .gitignore 里，clone 下来是空的，跑一次这个脚本即可。
# 可重复执行：已完整的文件会跳过，中断后重跑从断点继续。
#
# 用法：
#   ./scripts/setup.sh                # 全部
#   ./scripts/setup.sh --kokoro-only  # 只下载朗读模型
#   ./scripts/setup.sh --sd-only      # 只下载画图模型
#   ./scripts/setup.sh --skip-resolve # 不解析 SPM 依赖
#   ./scripts/setup.sh --open         # 完成后打开 Xcode 工程
#   HF_ENDPOINT=https://xxx ./scripts/setup.sh   # 换 Hugging Face 入口（默认 https://huggingface.co）
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HF="${HF_ENDPOINT:-https://huggingface.co}"

# ---- 模型来源（固定 commit，保证每台机器下到的文件一致；升级时改这里） ----
KOKORO_REPO="FluidInference/kokoro-82m-coreml"
KOKORO_REV="c94edcb4b671856795458645cd389c0a9184e8bb"   # 2026-06-14 "Upload 7 files"
KOKORO_DEST="$ROOT/BundledModels"

SD_REPO="apple/coreml-stable-diffusion-v1-5-palettized"
SD_REV="04a6a0bdd66fb8da470c14e56d762343ef579d88"
SD_REMOTE_DIR="split_einsum_v2/compiled"
SD_DEST="$ROOT/BundledStableDiffusion/sd15-palettized-split-einsum-v2"   # 与 StableDiffusionModelStore.localFolderName 一致

DO_KOKORO=1; DO_SD=1; DO_RESOLVE=1; DO_OPEN=0
for arg in "$@"; do
  case "$arg" in
    --kokoro-only) DO_SD=0 ;;
    --sd-only) DO_KOKORO=0 ;;
    --skip-resolve) DO_RESOLVE=0 ;;
    --open) DO_OPEN=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "未知参数: $arg"; exit 1 ;;
  esac
done

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
skip() { printf '  \033[2m· %s（已存在）\033[0m\n' "$*"; }
fail() { printf '  \033[31m✗ %s\033[0m\n' "$*"; }

for tool in curl python3; do
  command -v "$tool" >/dev/null || { fail "缺少 $tool"; exit 1; }
done

# 列出仓库文件：输出 "size<TAB>path"
hf_list() {  # repo rev
  curl -fsSL "$HF/api/models/$1/tree/$2?recursive=true" | python3 -c '
import json, sys
for e in json.load(sys.stdin):
    if e.get("type") == "file":
        print(str(e["size"]) + "\t" + e["path"])'
}

DOWNLOADED=0; SKIPPED=0; FAILED=0

# 下载单个文件：断点续传、重试、大小校验
fetch() {  # url dest size
  local url="$1" dest="$2" size="$3"
  if [[ -f "$dest" && "$(stat -f %z "$dest")" == "$size" ]]; then
    SKIPPED=$((SKIPPED + 1)); return 0
  fi
  mkdir -p "$(dirname "$dest")"
  local bar=""; [[ "$size" -gt 50000000 ]] && bar="--progress-bar"
  printf '  ↓ %s (%s)\n' "${dest#$ROOT/}" "$(python3 -c "print(f'{$size/1048576:.1f} MB')")"
  if curl -fL --retry 5 --retry-delay 3 -C - $bar -o "$dest.part" "$url" \
     && [[ "$(stat -f %z "$dest.part")" == "$size" ]]; then
    mv -f "$dest.part" "$dest"; DOWNLOADED=$((DOWNLOADED + 1))
  else
    fail "$dest 下载失败或大小不符"; rm -f "$dest.part"; FAILED=$((FAILED + 1))
  fi
}

# ---- 1. Kokoro ----
sync_kokoro() {
  bold "▶ Kokoro 朗读模型 → BundledModels/"
  local size path dest
  while IFS=$'\t' read -r size path; do
    dest=""
    case "$path" in
      # 语音合成主模型（FluidAudio 0.15.5 需要的 7 个 + 词表 + 音色）
      ANE/KokoroAlbert.mlmodelc/*|ANE/KokoroAlignment.mlmodelc/*|ANE/KokoroNoise_v2.mlmodelc/*| \
      ANE/KokoroPostAlbert.mlmodelc/*|ANE/KokoroProsody.mlmodelc/*|ANE/KokoroTail.mlmodelc/*| \
      ANE/KokoroVocoder.mlmodelc/*|ANE/vocab.json|ANE/af_heart.bin|ANE/LICENSE)
        dest="$KOKORO_DEST/kokoro-82m-coreml/$path" ;;
      # G2P（文字转音素）共享资产
      G2PDecoder.mlmodelc/*|G2PEncoder.mlmodelc/*|g2p_vocab.json|us_lexicon_cache.json)
        dest="$KOKORO_DEST/kokoro/$path" ;;
    esac
    if [[ -n "$dest" ]]; then
      fetch "$HF/$KOKORO_REPO/resolve/$KOKORO_REV/$path" "$dest" "$size"
    fi
  done < <(hf_list "$KOKORO_REPO" "$KOKORO_REV")
  ok "Kokoro 文件已就位"
}

# ---- 2. Stable Diffusion ----
sync_sd() {
  bold "▶ Stable Diffusion 画图模型 → BundledStableDiffusion/"
  local size path rel
  while IFS=$'\t' read -r size path; do
    case "$path" in
      "$SD_REMOTE_DIR"/SafetyChecker.mlmodelc/*|"$SD_REMOTE_DIR"/VAEEncoder.mlmodelc/*) continue ;;  # 文生图不需要，省 670 MB
      "$SD_REMOTE_DIR"/*) rel="${path#$SD_REMOTE_DIR/}" ;;
      *) continue ;;
    esac
    fetch "$HF/$SD_REPO/resolve/$SD_REV/$path" "$SD_DEST/$rel" "$size"
  done < <(hf_list "$SD_REPO" "$SD_REV")
  ok "Stable Diffusion 文件已就位"
}

# 注意：不能写成 [[ ... ]] && func，函数返回非 0 会触发 set -e 直接退出
if [[ $DO_KOKORO -eq 1 ]]; then sync_kokoro; fi
if [[ $DO_SD -eq 1 ]]; then sync_sd; fi

echo
bold "模型文件：新下载 ${DOWNLOADED}，已存在跳过 ${SKIPPED}，失败 ${FAILED}"
if [[ $DO_KOKORO -eq 1 ]]; then ok "BundledModels: $(du -sh "$KOKORO_DEST" 2>/dev/null | cut -f1)"; fi
if [[ $DO_SD -eq 1 ]]; then ok "BundledStableDiffusion: $(du -sh "$SD_DEST" 2>/dev/null | cut -f1)"; fi
if [[ $FAILED -gt 0 ]]; then
  fail "有文件没下完，检查网络后重新运行本脚本即可续传"; exit 1
fi

# ---- 3. SPM ----
if [[ $DO_RESOLVE -eq 1 ]]; then
  echo
  bold "▶ 解析 Swift Package 依赖"
  if command -v xcodebuild >/dev/null; then
    xcodebuild -project "$ROOT/RainbowKingdom.xcodeproj" -resolvePackageDependencies -quiet && ok "依赖已解析"
  else
    fail "没有 xcodebuild，跳过（安装 Xcode 后在 Xcode 里打开工程会自动解析）"
  fi
fi

echo
bold "完成。用 Xcode 打开 RainbowKingdom.xcodeproj，选真机运行。"
if [[ $DO_OPEN -eq 1 ]]; then open "$ROOT/RainbowKingdom.xcodeproj"; fi
exit 0
