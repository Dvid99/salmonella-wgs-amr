#!/usr/bin/env bash
# Step 0 — Download the reads from ENA and the S. Typhimurium LT2 reference from NCBI.
#   bash scripts/00_download_data.sh
#   CONFIG=config/test.sh bash scripts/00_download_data.sh   # also writes the subsample
source "$(dirname "$0")/utils/common.sh"
require wget

mkdir -p "$(dirname "$R1")" "$REF_DIR"

# Paired FASTQs: ask the ENA portal API for the file URLs
if [[ ! -s "$R1" || ! -s "$R2" ]]; then
    log "Reads: $SAMPLE (ENA)"
    urls="$(wget -qO- "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${SAMPLE}&result=read_run&fields=fastq_ftp&format=tsv" | tail -n 1 | cut -f2)"
    for u in ${urls//;/ }; do
        wget -nc -q -P "$(dirname "$R1")" "https://${u}"
    done
fi

# Reference genome (FASTA) and annotation (GenBank) for Prokka
for ext in genomic.fna genomic.gbff; do
    if [[ ! -s "${REF_DIR}/${REF_NAME}_${ext}" ]]; then
        log "Reference: ${REF_NAME}_${ext}"
        wget -qO- "${REF_URL}/${REF_NAME}_${ext}.gz" | gunzip > "${REF_DIR}/${REF_NAME}_${ext}"
    fi
done

# Optional subsample for quick tests
if [[ -n "$SUBSAMPLE" ]]; then
    require seqtk
    read -r s1 s2 <<< "$(input_reads)"
    mkdir -p "$(dirname "$s1")"
    if [[ ! -s "$s1" ]]; then
        log "Subsampling ${SUBSAMPLE} of the read pairs"
        seqtk sample -s 42 "$R1" "$SUBSAMPLE" | gzip > "$s1"
        seqtk sample -s 42 "$R2" "$SUBSAMPLE" | gzip > "$s2"
    fi
fi
ls -lh "$(dirname "$R1")" "$REF_DIR"
