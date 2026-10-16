# Pipeline configuration (paths relative to the repository root).
# Use another file with:  CONFIG=config/test.sh bash scripts/run_all.sh

SAMPLE="SRR18072959"                  # Salmonella enterica clinical isolate, Illumina 2 x 251 bp
R1="data/raw/${SAMPLE}_1.fastq.gz"
R2="data/raw/${SAMPLE}_2.fastq.gz"
SUBSAMPLE=""                          # e.g. 0.1 to keep 10% of the read pairs (quick test)

# Reference used for annotation and assembly comparison: S. Typhimurium LT2 (RefSeq)
REF_NAME="GCF_000006945.2_ASM694v2"
REF_URL="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/945/${REF_NAME}"
REF_DIR="data/reference"
GENOME_SIZE=4951383                   # LT2 chromosome + pSLT, for the expected-coverage estimate

OUT_DIR="results"
THREADS=4
SPADES_MEM_GB=12

# fastp: minimum length and mean/leading/trailing quality
MIN_LENGTH=151
MIN_QUAL=25

# Contig filter before annotation (step 5)
MIN_CONTIG_LEN=500                    # bp
MIN_DEPTH_FRACTION=0.25               # keep contigs with depth >= 25% of the main-genome depth

# AMRFinderPlus thresholds
AMR_ORGANISM="Salmonella"
AMR_MIN_IDENTITY=0.9
AMR_MIN_COVERAGE=0.9
