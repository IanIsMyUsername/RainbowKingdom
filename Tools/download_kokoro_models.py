#!/usr/bin/env python3
"""下载 Kokoro-82M 英文 TTS 模型到 BundledModels/（约 95MB）。

BundledModels/ 不入 git（太大），clone 仓库后运行本脚本一次即可：
    python3 Tools/download_kokoro_models.py

目录布局对应 FluidAudio 0.15.5 的要求（升级 FluidAudio 版本时需重新核对，
见 KokoroModelInstaller.swift 注释）：
    BundledModels/kokoro-82m-coreml/ANE/   7 个 mlmodelc + vocab.json + af_heart.bin
    BundledModels/kokoro/                  G2P 模型 + 词表 + Misaki 词典
"""
import json
import os
import sys
import urllib.request

REPO = "FluidInference/kokoro-82m-coreml"
DEST = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "BundledModels")

# 远端路径前缀/文件 -> 本地目录映射
ANE_PREFIXES = [
    "ANE/KokoroAlbert.mlmodelc/",
    "ANE/KokoroPostAlbert.mlmodelc/",
    "ANE/KokoroAlignment.mlmodelc/",
    "ANE/KokoroProsody.mlmodelc/",
    "ANE/KokoroNoise_v2.mlmodelc/",
    "ANE/KokoroVocoder.mlmodelc/",
    "ANE/KokoroTail.mlmodelc/",
]
ANE_FILES = ["ANE/vocab.json", "ANE/af_heart.bin", "ANE/LICENSE"]
G2P_PREFIXES = ["G2PEncoder.mlmodelc/", "G2PDecoder.mlmodelc/"]
G2P_FILES = ["g2p_vocab.json", "us_lexicon_cache.json"]


def local_path(remote):
    """远端路径映射到 BundledModels 内的本地路径，不需要的文件返回 None。"""
    if remote in ANE_FILES or any(remote.startswith(p) for p in ANE_PREFIXES):
        return os.path.join("kokoro-82m-coreml", remote)
    if remote in G2P_FILES or any(remote.startswith(p) for p in G2P_PREFIXES):
        return os.path.join("kokoro", remote)
    return None


def main():
    api = f"https://huggingface.co/api/models/{REPO}/tree/main?recursive=true"
    with urllib.request.urlopen(api) as r:
        files = json.load(r)

    targets = []
    for f in files:
        if f["type"] != "file":
            continue
        local = local_path(f["path"])
        if local:
            size = f.get("size") or (f.get("lfs") or {}).get("size", 0)
            targets.append((f["path"], local, size))

    total = sum(t[2] for t in targets)
    print(f"{len(targets)} files, {total / 1024 / 1024:.0f}MB total")

    for i, (remote, local, size) in enumerate(targets):
        dest = os.path.join(DEST, local)
        if os.path.exists(dest) and os.path.getsize(dest) == size:
            print(f"[{i + 1}/{len(targets)}] skip {local}")
            continue
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        url = f"https://huggingface.co/{REPO}/resolve/main/{remote}"
        tmp = dest + ".part"
        for attempt in range(5):
            try:
                urllib.request.urlretrieve(url, tmp)
                break
            except Exception as e:
                print(f"  retry {attempt + 1} for {remote}: {e}")
        else:
            sys.exit(f"FAILED: {remote}")
        os.replace(tmp, dest)
        print(f"[{i + 1}/{len(targets)}] ok {local} ({size / 1024 / 1024:.1f}MB)")

    print("DONE")


if __name__ == "__main__":
    main()
