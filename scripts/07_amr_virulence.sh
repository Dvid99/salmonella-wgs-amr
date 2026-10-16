#!/usr/bin/env bash
# Step 7 — Antimicrobial resistance, stress (metals, biocides) and virulence genes
# with NCBI AMRFinderPlus (--plus), >= 90% identity and >= 90% coverage.
# Combined mode (proteins + contigs + GFF) also screens Salmonella point mutations
# (e.g. gyrA/parC quinolone resistance), which protein-only searches cannot see.
source "$(dirname "$0")/utils/common.sh"
require amrfinder

prk="${OUT_DIR}/06_prokka/${SAMPLE}"
out="${OUT_DIR}/07_amrfinder"
mkdir -p "$out"

# Download the database once (stored inside the conda environment)
amrfinder --database_version > /dev/null 2>&1 || amrfinder -u

amrfinder \
    -p "${prk}.faa" -n "${prk}.fna" -g "${prk}.gff" -a prokka \
    --organism "$AMR_ORGANISM" --plus \
    -i "$AMR_MIN_IDENTITY" -c "$AMR_MIN_COVERAGE" \
    --threads "$THREADS" -o "${out}/${SAMPLE}.amrfinder.tsv" 2> "${out}/amrfinder.log"

amrfinder --version | sed 's/^/AMRFinderPlus /' | tee "${out}/versions.txt"
amrfinder --database_version 2>/dev/null | tee -a "${out}/versions.txt"
echo
# Gene symbol, element type/subtype, class, method, %identity, %coverage
awk -F'\t' 'NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i }
    { print $col["Gene symbol"], $col["Element type"], $col["Element subtype"], $col["Class"],
            $col["Method"], $col["% Identity to reference sequence"], $col["% Coverage of reference sequence"] }' \
    OFS='\t' "${out}/${SAMPLE}.amrfinder.tsv" | column -t -s $'\t'
