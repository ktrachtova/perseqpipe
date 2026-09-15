#!/usr/bin/env python3
"""
Build a miraligner-compatible {species}.hairpin.fa / {species}.miRNA.str
database pair from MirGeneDB's own precursor FASTA and "-all" BED files
(https://www.mirgenedb.org).

This is adapted from mirtop's scripts/create_mirgenedb.sh + prepare.py
(https://github.com/miRTop/mirtop/blob/master/scripts/prepare.py). MirGeneDB
offers two precursor FASTA flavors:
  - "-pre.fas": exact precursor/hairpin sequence, no flanking (flank=0)
  - "-pri.fas": precursor +/-30nt flanking sequence (flank=30)
Mature-arm coordinates (from the BED's "_pre" entry) are always computed
relative to the exact precursor, then shifted by --flank to account for any
padding present in the FASTA. --flank is auto-detected from the FASTA header
suffix ('_pre' -> 0, '_pri' -> 30) unless given explicitly.

Usage:
    create_mirgenedb_db.py --bed hsa-all.bed --fasta hsa-pre.fas --species hsa --outdir mirgene
    create_mirgenedb_db.py --bed hsa-all.bed --fasta hsa-pri.fas --species hsa --outdir mirgene
"""
import argparse
import os
from collections import defaultdict

DEFAULT_FLANK_BY_SUFFIX = {"_pre": 0, "_pri": 30}


def read_precursors(fasta_path):
    precursors = {}
    name = None
    suffix = None
    with open(fasta_path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            if line.startswith(">"):
                header = line[1:]
                suffix = "_pri" if header.endswith("_pri") else "_pre"
                name = header.removesuffix(suffix)
            else:
                precursors[name] = line
    return precursors, suffix


def read_bed(bed_path):
    loci = defaultdict(dict)
    with open(bed_path) as fh:
        for line in fh:
            cols = line.rstrip("\n").split("\t")
            name = cols[3]
            # skip primary-transcript flanks and sub-annotations we don't need
            if any(tag in name for tag in ("_pri", "_loop", "_seed", "_motif", "_co")):
                continue
            gene = name.split("_")[0]
            loci[gene][name] = (int(cols[1]), int(cols[2]), cols[5])
    return loci


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bed", required=True, help="MirGeneDB '*-all.bed' file")
    parser.add_argument("--fasta", required=True, help="MirGeneDB '*-pre.fas' or '*-pri.fas' precursor FASTA")
    parser.add_argument("--species", required=True, help="3-letter species code, e.g. hsa")
    parser.add_argument("--outdir", default=".", help="Output directory")
    parser.add_argument("--flank", type=int, default=None,
                         help="nt of flanking sequence in --fasta (default: auto-detect from header suffix)")
    args = parser.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    precursors, suffix = read_precursors(args.fasta)
    loci = read_bed(args.bed)
    flank = args.flank if args.flank is not None else DEFAULT_FLANK_BY_SUFFIX[suffix]
    print(f"Using flank={flank} (detected from '{suffix}' header suffix)" if args.flank is None else f"Using flank={flank} (explicit)")

    str_path = os.path.join(args.outdir, f"{args.species}.miRNA.str")
    fa_path = os.path.join(args.outdir, f"{args.species}.hairpin.fa")

    n_written = 0
    with open(str_path, "w") as out_str, open(fa_path, "w") as out_fa:
        for gene, seq in precursors.items():
            entries = loci.get(gene)
            if not entries or (gene + "_pre") not in entries:
                continue

            pre_start, pre_end, pre_strand = entries[gene + "_pre"]
            mir5p, mir3p = "", ""

            for mature_name, (m_start, m_end, _strand) in entries.items():
                if mature_name.endswith("_pre"):
                    continue
                if pre_strand == "-":
                    start = pre_end - m_end + 1 + flank
                    end = pre_end - m_start + flank
                else:
                    start = m_start - pre_start + 1 + flank
                    end = m_end - pre_start + flank

                if "5p" in mature_name:
                    mir5p = f"[{mature_name}:{start}-{end}]"
                if "3p" in mature_name:
                    mir3p = f"[{mature_name}:{start}-{end}]"

            out_str.write(f">{gene} (X) {mir5p} {mir3p}\n")
            out_fa.write(f">{gene}\n{seq}\n")
            n_written += 1

    print(f"Wrote {n_written} precursors to {fa_path} and {str_path}")


if __name__ == "__main__":
    main()
