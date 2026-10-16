#!/usr/bin/env bash
# Shared helpers sourced by every step.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
CONFIG="${CONFIG:-config/config.sh}"
# shellcheck source=../../config/config.sh
source "$CONFIG"

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }

require() {
    for tool in "$@"; do
        command -v "$tool" >/dev/null 2>&1 || { log "ERROR: '$tool' not found — activate the right conda environment (see README)"; exit 1; }
    done
}

# Input reads, subsampled when SUBSAMPLE is set (written once to data/subsampled/)
input_reads() {
    if [[ -z "${SUBSAMPLE}" ]]; then
        printf '%s %s' "$R1" "$R2"
    else
        printf 'data/subsampled/%s_%s_1.fastq.gz data/subsampled/%s_%s_2.fastq.gz' \
            "$SAMPLE" "$SUBSAMPLE" "$SAMPLE" "$SUBSAMPLE"
    fi
}
