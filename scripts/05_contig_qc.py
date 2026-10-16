#!/usr/bin/env python3
"""Step 5 — Per-contig QC (length, GC, read depth) and contig filtering.

The main chromosome of an isolate assembles into long contigs with similar depth.
Contaminant DNA, sequencing artefacts and fragments tend to appear as many short
contigs with different depth and GC. This script:
  * estimates the main-genome depth as the length-weighted median depth of the
    contigs >= 10 kb,
  * keeps contigs >= --min-len bp with depth >= --min-depth-fraction x that value,
  * writes the filtered assembly, a per-contig table, a summary and a plot.

Usage:
  python scripts/05_contig_qc.py results/03_spades/contigs.fasta \
      results/04_assembly_qc/contig_coverage.tsv --outdir results/05_contig_qc
"""
import argparse
import os
from pathlib import Path

os.environ["MPLBACKEND"] = "Agg"          # notebooks (e.g. Colab) export an inline backend
import matplotlib.pyplot as plt  # noqa: E402
import pandas as pd  # noqa: E402


def read_fasta(path):
    name, seq = None, []
    with open(path) as fh:
        for line in fh:
            line = line.rstrip()
            if line.startswith(">"):
                if name:
                    yield name, "".join(seq)
                name, seq = line[1:].split()[0], []
            else:
                seq.append(line)
    if name:
        yield name, "".join(seq)


def weighted_median(values, weights):
    df = pd.DataFrame({"v": values, "w": weights}).sort_values("v")
    cum = df.w.cumsum()
    return float(df.v[cum >= df.w.sum() / 2].iloc[0])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("contigs", type=Path)
    ap.add_argument("coverage", type=Path, help="samtools coverage output")
    ap.add_argument("--outdir", type=Path, default=Path("results/05_contig_qc"))
    ap.add_argument("--min-len", type=int, default=500)
    ap.add_argument("--min-depth-fraction", type=float, default=0.25)
    args = ap.parse_args()
    args.outdir.mkdir(parents=True, exist_ok=True)

    seqs = dict(read_fasta(args.contigs))
    cov = pd.read_csv(args.coverage, sep="\t").rename(columns={"#rname": "contig"})
    df = pd.DataFrame({
        "contig": list(seqs),
        "length": [len(s) for s in seqs.values()],
        "gc": [100 * (s.upper().count("G") + s.upper().count("C")) / max(len(s), 1) for s in seqs.values()],
    }).merge(cov[["contig", "meandepth", "coverage"]], on="contig", how="left").fillna(0)

    long = df[df.length >= 10_000]
    main_depth = weighted_median(long.meandepth, long.length) if len(long) else df.meandepth.median()
    min_depth = args.min_depth_fraction * main_depth
    df["keep"] = (df.length >= args.min_len) & (df.meandepth >= min_depth)
    df.to_csv(args.outdir / "contig_table.tsv", sep="\t", index=False)

    with open(args.outdir / "contigs.filtered.fasta", "w") as fh:
        for name in df.contig[df.keep]:
            s = seqs[name]
            fh.write(f">{name}\n" + "\n".join(s[i:i + 80] for i in range(0, len(s), 80)) + "\n")

    def block(sub):
        gc = (sub.gc * sub.length).sum() / max(sub.length.sum(), 1)
        return len(sub), int(sub.length.sum()), round(gc, 2)

    rows = [("all contigs", *block(df)),
            (f"contigs >= {args.min_len} bp", *block(df[df.length >= args.min_len])),
            ("contigs >= 10 kb", *block(long)),
            ("kept (length + depth filter)", *block(df[df.keep])),
            ("removed", *block(df[~df.keep]))]
    summary = pd.DataFrame(rows, columns=["set", "contigs", "total_bp", "gc_percent"])
    summary.to_csv(args.outdir / "summary.tsv", sep="\t", index=False)
    print(f"Main-genome depth (length-weighted median, contigs >= 10 kb): {main_depth:.1f}x")
    print(f"Depth threshold: {min_depth:.1f}x  |  min length: {args.min_len} bp\n")
    print(summary.to_string(index=False))

    # Length vs depth, coloured by GC
    fig, ax = plt.subplots(figsize=(7.5, 5))
    sc = ax.scatter(df.length, df.meandepth.clip(lower=0.1), c=df.gc, cmap="viridis",
                    s=8 + 60 * (df.length / df.length.max()), alpha=0.7, edgecolors="none")
    ax.axhline(min_depth, ls="--", c="grey", lw=1)
    ax.axvline(args.min_len, ls="--", c="grey", lw=1)
    ax.set(xscale="log", yscale="log", xlabel="Contig length (bp)", ylabel="Mean read depth (x)",
           title="SPAdes contigs: length vs depth")
    fig.colorbar(sc, ax=ax, label="GC (%)")
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(args.outdir / "contig_length_vs_depth.png", dpi=150)


if __name__ == "__main__":
    main()
