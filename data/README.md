# Data

No data is stored in this repository; everything is public and downloaded by `bash scripts/00_download_data.sh`.

| Input | Source |
|---|---|
| Paired-end reads, *Salmonella enterica* clinical isolate (Illumina, 2 × 251 bp, ~1.6 M pairs) | SRA/ENA [`SRR18072959`](https://www.ebi.ac.uk/ena/browser/view/SRR18072959) → `data/raw/` |
| Reference: *S. enterica* serovar Typhimurium LT2, RefSeq `GCF_000006945.2` (genome FASTA + GenBank) | [NCBI](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_000006945.2/) → `data/reference/` |
| AMRFinderPlus database | downloaded by `amrfinder -u` on first use |
