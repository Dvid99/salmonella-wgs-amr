#!/usr/bin/env bash
# Step 2 — Quality trimming and filtering with fastp, then FastQC on the clean reads.
source "$(dirname "$0")/utils/common.sh"
require fastp fastqc

read -r in1 in2 <<< "$(input_reads)"
out="${OUT_DIR}/02_trimmed"
mkdir -p "$out"

log "fastp: min length ${MIN_LENGTH} bp, quality Q${MIN_QUAL}"
fastp \
    -i "$in1" -I "$in2" \
    -o "${out}/${SAMPLE}_1.clean.fq.gz" -O "${out}/${SAMPLE}_2.clean.fq.gz" \
    --length_required "$MIN_LENGTH" \
    --average_qual "$MIN_QUAL" \
    --cut_front --cut_front_mean_quality "$MIN_QUAL" \
    --cut_tail  --cut_tail_mean_quality  "$MIN_QUAL" \
    --detect_adapter_for_pe \
    --thread "$THREADS" \
    --html "${out}/${SAMPLE}.fastp.html" --json "${out}/${SAMPLE}.fastp.json"

if [[ -z "$(zcat "${out}/${SAMPLE}_1.clean.fq.gz" | head -c 1)" ]]; then
    log "ERROR: no reads passed the filters — check MIN_LENGTH/MIN_QUAL"
    exit 1
fi
fastqc --threads "$THREADS" --outdir "$out" "${out}/${SAMPLE}_1.clean.fq.gz" "${out}/${SAMPLE}_2.clean.fq.gz"
