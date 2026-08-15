#!/usr/bin/env python3
"""Extract sequences from a srna_counts_tsv, run tDRnamer against them and merge the
resulting tDR_name back into the table as a new 'tdr_name' column."""
import argparse
import subprocess

import pandas as pd


def main():
    parser = argparse.ArgumentParser(description="Annotate srna_counts_tsv with tDRnamer tDR names.")
    parser.add_argument("--srna_counts_tsv", required=True, help="Input short RNA counts TSV with a 'sequence' column")
    parser.add_argument("--db", required=True, help="tDRnamer database prefix, e.g. hg38/hg38")
    parser.add_argument("--source", default="euk", help="tDRnamer --source argument")
    parser.add_argument("--output_prefix", required=True)
    args = parser.parse_args()

    df = pd.read_csv(args.srna_counts_tsv, sep="\t", dtype=str)

    # Only sequences already overlapping a known tRNA locus are worth naming
    trna_df = df[df["trna"].fillna("") != ""]

    fasta_path = f"{args.output_prefix}.sequences.fasta"
    with open(fasta_path, "w") as fasta:
        for i, seq in enumerate(trna_df["sequence"]):
            fasta.write(f">seq_{i}\n{seq}\n")

    subprocess.run(
        [
            "tDRnamer",
            "--mode", "seq",
            "--seq", fasta_path,
            "--db", args.db,
            "--source", args.source,
            "--output", args.output_prefix,
        ],
        check=True,
    )

    tdr_info = pd.read_csv(f"{args.output_prefix}-tDR-info.txt", sep="\t", dtype=str)

    # tDRnamer reports RNA sequences (U); srna_counts_tsv sequences are DNA (T)
    tdr_seq_to_name = dict(
        zip(tdr_info["sequence"].str.upper().str.replace("U", "T", regex=False), tdr_info["tDR_name"])
    )

    df["tdr_name"] = df["sequence"].map(tdr_seq_to_name).fillna("")
    df.to_csv(f"{args.output_prefix}.short_rna_counts.tsv", index=False, sep="\t")


if __name__ == "__main__":
    main()
