#!/usr/bin/env bash
# Run every step in order. Steps 1-5 use envs/assembly.yml, steps 6-7 envs/annotation.yml:
#   conda activate salmonella-assembly  && bash scripts/run_all.sh assembly
#   conda activate salmonella-annotation && bash scripts/run_all.sh annotation
source "$(dirname "$0")/utils/common.sh"

stage="${1:-all}"
if [[ "$stage" == "all" || "$stage" == "assembly" ]]; then
    for step in 01_qc_raw 02_trim 03_assemble 04_assembly_qc; do
        log "===== ${step} ====="
        CONFIG="$CONFIG" bash "scripts/${step}.sh"
    done
    log "===== 05_contig_qc ====="
    python scripts/05_contig_qc.py "${OUT_DIR}/03_spades/contigs.fasta" \
        "${OUT_DIR}/04_assembly_qc/contig_coverage.tsv" --outdir "${OUT_DIR}/05_contig_qc" \
        --min-len "$MIN_CONTIG_LEN" --min-depth-fraction "$MIN_DEPTH_FRACTION"
fi
if [[ "$stage" == "all" || "$stage" == "annotation" ]]; then
    for step in 06_annotate 07_amr_virulence; do
        log "===== ${step} ====="
        CONFIG="$CONFIG" bash "scripts/${step}.sh"
    done
fi
