#!/bin/bash
# Cópia criptografada, no OneDrive, do que só existe neste PC (o resto está no GitHub).
# Sobe ~/dev, ~/Documentos e ~/.claude, sem o que se refaz sozinho (ver filtros.txt).
# O que mudar ou sumir aqui não some lá: a versão anterior vai para versoes-antigas/<data>.
#
# Uso: ./backup-nuvem.sh            copia de verdade
#      ./backup-nuvem.sh --dry-run  só mostra o que faria
set -euo pipefail

REMOTO="${REMOTO:-nuvem-cripto:}"
PASTA="$(cd "$(dirname "$0")" && pwd)"
LOG="$HOME/.local/state/backup-nuvem.log"
DATA="$(date +%Y-%m-%d_%H%M)"
mkdir -p "$(dirname "$LOG")"

for item in dev Documentos .claude; do
  rclone sync "$HOME/$item" "${REMOTO}atual/$item" \
    --filter-from "$PASTA/filtros.txt" \
    --backup-dir "${REMOTO}versoes-antigas/$DATA/$item" \
    --transfers 4 --checkers 8 \
    --log-file "$LOG" --log-level INFO --stats-one-line \
    "$@"
done
echo "$(date '+%d/%m %H:%M') backup terminou" >> "$LOG"
