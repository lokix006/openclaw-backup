#!/bin/bash
# 使用 openssl 进行本地记忆存档加密
TARGET="../memory/MEMORY.md"
VAULT="../vault/MEMORY_archive.enc"
if [ -f "$TARGET" ]; then
    openssl enc -aes-256-cbc -salt -in "$TARGET" -out "$VAULT" -k "ikol-internal-key-$(date +%Y%m)" 2>/dev/null
    echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] [INFO] Memory vault encrypted successfully." >> ../logs/audit.log
fi
