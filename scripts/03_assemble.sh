#!/usr/bin/env bash
# Step 3 — De novo assembly with SPAdes in --careful mode (read error correction
# with BayesHammer, multi-k assembly, and mismatch/short-indel correction).
# --phred-offset 33: the ENA FASTQs carry binned qualities, so SPAdes cannot
# detect the encoding by itself.
source "$(dirname "$0")/utils/common.sh"
require spades.py

trim="${OUT_DIR}/02_trimmed"
out="${OUT_DIR}/03_spades"

if ! spades.py --careful --phred-offset 33 \
        -1 "${trim}/${SAMPLE}_1.clean.fq.gz" -2 "${trim}/${SAMPLE}_2.clean.fq.gz" \
        -t "$THREADS" -m "$SPADES_MEM_GB" -o "$out" > "${OUT_DIR}/03_spades.stdout.log" 2>&1; then
    log "ERROR: SPAdes failed — last lines of the log:"
    tail -n 30 "${OUT_DIR}/03_spades.stdout.log" >&2
    exit 1
fi

# k-mer sizes tried; contigs.fasta comes from the largest k (K<max> folder)
ks="$(find "$out" -maxdepth 1 -type d -name 'K*' -printf '%f\n' | sort -V | tr '\n' ' ')"
log "k-mers tested: ${ks}"
log "Final k: $(tr ' ' '\n' <<< "$ks" | grep . | tail -n 1)"
log "Contigs: $(grep -c '>' "${out}/contigs.fasta")"
