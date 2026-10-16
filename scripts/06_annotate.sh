#!/usr/bin/env bash
# Step 6 — Genome annotation with Prokka, using the S. Typhimurium LT2 RefSeq
# proteome as the primary database. Annotates the filtered contigs from step 5;
# set ANNOTATE_ALL=1 to annotate every contig, as in the original exercise.
source "$(dirname "$0")/utils/common.sh"
require prokka prokka-genbank_to_fasta_db

out="${PROKKA_OUT:-${OUT_DIR}/06_prokka}"
mkdir -p "$out"
ref_prots="${REF_DIR}/${REF_NAME}_proteins.faa"

if [[ ! -s "$ref_prots" ]]; then
    prokka-genbank_to_fasta_db "${REF_DIR}/${REF_NAME}_genomic.gbff" > "$ref_prots" 2> /dev/null
fi
log "Reference proteins (LT2): $(grep -c '>' "$ref_prots")"

if [[ "${ANNOTATE_ALL:-0}" == "1" ]]; then
    contigs="${OUT_DIR}/03_spades/contigs.fasta"
else
    contigs="${OUT_DIR}/05_contig_qc/contigs.filtered.fasta"
fi
log "Annotating: $contigs"

prokka --outdir "$out" --prefix "$SAMPLE" --force \
    --kingdom Bacteria --genus Salmonella --species enterica --usegenus \
    --proteins "$ref_prots" --addgenes --addmrna --compliant --mincontiglen 0 \
    --cpus "$THREADS" "$contigs" > "${out}/prokka.stdout.log" 2>&1
cat "${out}/${SAMPLE}.txt"
