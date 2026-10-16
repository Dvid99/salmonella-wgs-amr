#!/usr/bin/env bash
# Step 4 — Assembly QC:
#   a) QUAST on all contigs, and against the LT2 reference (genome fraction,
#      unaligned length -> how much of the assembly is not Salmonella-like)
#   b) map the clean reads back to the contigs (BWA-MEM) -> mapped reads and
#      per-contig depth (samtools coverage), used by step 5
source "$(dirname "$0")/utils/common.sh"
require quast.py bwa samtools

contigs="${OUT_DIR}/03_spades/contigs.fasta"
trim="${OUT_DIR}/02_trimmed"
out="${OUT_DIR}/04_assembly_qc"
mkdir -p "$out"

log "QUAST (all contigs >= 500 bp, default)"
quast.py "$contigs" -o "${out}/quast" -t "$THREADS" > "${out}/quast.log" 2>&1
log "QUAST vs S. Typhimurium LT2"
quast.py "$contigs" -r "${REF_DIR}/${REF_NAME}_genomic.fna" -o "${out}/quast_vs_LT2" -t "$THREADS" \
    > "${out}/quast_vs_LT2.log" 2>&1
grep -E "^(# contigs|Largest contig|Total length|GC|N50|N90|L50|L90|Genome fraction|Unaligned length)" \
    "${out}/quast_vs_LT2/report.txt" || true

log "Mapping clean reads back to the contigs"
bwa index "$contigs" 2> /dev/null
bwa mem -t "$THREADS" "$contigs" "${trim}/${SAMPLE}_1.clean.fq.gz" "${trim}/${SAMPLE}_2.clean.fq.gz" 2> "${out}/bwa.log" |
    samtools sort -@ "$THREADS" -o "${out}/reads_vs_contigs.bam" -
samtools index "${out}/reads_vs_contigs.bam"
samtools flagstat "${out}/reads_vs_contigs.bam" | tee "${out}/flagstat.txt"
samtools coverage "${out}/reads_vs_contigs.bam" > "${out}/contig_coverage.tsv"

# Expected coverage (Lander-Waterman: total clean bases / genome size of LT2)
python - "${trim}/${SAMPLE}.fastp.json" "$GENOME_SIZE" <<'EOF' | tee "${out}/expected_coverage.txt"
import json, sys
bases = json.load(open(sys.argv[1]))["summary"]["after_filtering"]["total_bases"]
print(f"Clean bases: {bases:,} | genome size: {int(sys.argv[2]):,} bp | expected coverage: {bases / int(sys.argv[2]):.0f}x")
EOF
