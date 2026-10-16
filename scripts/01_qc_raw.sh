#!/usr/bin/env bash
# Step 1 — Quality control of the raw paired-end reads (FastQC).
source "$(dirname "$0")/utils/common.sh"
require fastqc

read -r in1 in2 <<< "$(input_reads)"
out="${OUT_DIR}/01_qc_raw"
mkdir -p "$out"
fastqc --threads "$THREADS" --outdir "$out" "$in1" "$in2"
