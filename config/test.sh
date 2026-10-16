# Quick test: same isolate, 10% of the read pairs (~16x). Checks that every
# step runs in a few minutes; assembly statistics are not comparable.
source config/config.sh
SUBSAMPLE=0.1
OUT_DIR="results_test"
THREADS=2
SPADES_MEM_GB=10
