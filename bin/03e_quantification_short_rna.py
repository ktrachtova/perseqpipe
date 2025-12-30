#!/usr/bin/env python3
"""
Quantification of small non-coding RNAs from BAM alignments using GTF annotations.

This script counts read alignments overlapping annotated RNA loci (tRNA, piRNA, snoRNA, etc.),
filters overlaps based on a minimum overlap length or fraction, and generates a merged count table.

Author: Karolina Trachtova
"""

import os
import time
import argparse
import logging
import collections
from collections import defaultdict

import HTSeq
import pandas as pd

from MINTplates_module import *
from utils import *

# Example usage:
# 03e_quantification_short_rna.py \
#      SRR12899270_VOVP02_50k.genome.Aligned.sortedByCoord.out.bam \
#      perseqpipe_all_sncrna_v1.0.gtf \
#      --sample_name SRR12899270_VOVP02_50k.genome

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%d/%m/%Y:%H:%M"
)


def add_mint_plates(df):
    """
    Add MINT license plates for every sequence.

    Each sequence is converted into a unique license plate using the
    Jefferson MINTplate generator (https://cm.jefferson.edu/license-plates-download/).

    Parameters
    ----------
    df : pandas.DataFrame
        DataFrame with a 'sequence' column.

    Returns
    -------
    pandas.DataFrame
        Input DataFrame with an additional 'MINT_plate' column.
    """
    mint_plates = []
    # Go over rownames/index of the data frame and add licence plate
    # by default, 'seq' is added as a prefix
    for sequence in df['sequence']:
        mint_plates.append(run_as_script(sequence, 'en', 'seq'))
    df['MINT_plate'] = mint_plates
    return df


def main():
    """Main entry point for small RNA quantification."""
    start_time = time.time()
    logging.info("Script execution started.")

    # -------------------------------------------------------------------------
    # Argument parsing
    # -------------------------------------------------------------------------
    parser = argparse.ArgumentParser(description="Script for counting short sequences from small RNA sequencing data.")
    parser.add_argument("input_bam", help="Input BAM file")
    parser.add_argument("input_gtf", help="Input GTF file")
    parser.add_argument("--merge_identical", action="store_true", help="Merge sequences with identical annotations")
    parser.add_argument("--sample_name", help="Sample name for output files (optional)")
    parser.add_argument("--output_dir", help="Output directory (optional)")
    parser.add_argument("--reads_threshold",
                        type=int,
                        help="Reads thresholds, any read with expression lower than this value will not be counted, default 1 (all reads are counted)",
                        default=1)
    parser.add_argument("--overlap_bp", type=int, default=5,
        help="Minimum total bp of overlap with a feature to keep it (default 5)")
    parser.add_argument("--overlap_frac", type=float, default=None,
        help="Minimum fraction of read length (0-1) that must overlap a feature (optional)")


    args = parser.parse_args()

   # -------------------------------------------------------------------------
    # Load input files
    # -------------------------------------------------------------------------
    logging.info("Loading BAM file: %s", args.input_bam)
    bamfile = HTSeq.BAM_Reader(args.input_bam)

    logging.info("Reading and parsing GTF annotations...")
    gene_df, trna_df, snorna_df, srna_df, pirna_df, mrna_df, lncrna_df = parse_rna_classes(args.input_gtf)
    rna_arrays = parse_gtf_for_quantification(gene_df, trna_df, snorna_df, srna_df, pirna_df, mrna_df, lncrna_df)
    logging.info("Finished parsing GTF annotations.")

    # -------------------------------------------------------------------------
    # Initialize containers
    # -------------------------------------------------------------------------
    trna = rna_arrays['trna']
    snorna = rna_arrays['snorna']
    srna = rna_arrays['other_sncrna']
    pirna = rna_arrays['pirna']
    mrna = rna_arrays['mrna']
    lncrna = rna_arrays['lncrna']

    # Prepare collections for counting sequences for individual RNA classes
    counts = collections.Counter()
    multimappings = collections.Counter()

    read_overlaps_trna = defaultdict(lambda: defaultdict(list))
    read_overlaps_pirna = defaultdict(lambda: defaultdict(list))
    read_overlaps_snorna = defaultdict(lambda: defaultdict(list))
    read_overlaps_srna = defaultdict(lambda: defaultdict(list))
    read_overlaps_mrna = defaultdict(lambda: defaultdict(list))
    read_overlaps_lncrna = defaultdict(lambda: defaultdict(list))

    logging.info("Counting reads...")

    # -------------------------------------------------------------------------
    # Iterate over all read bundles (multi-mapping reads)
    # -------------------------------------------------------------------------
    # Go over every bundle (=iterator over multiple alignments of one specific read)
    for bundle in HTSeq.bundle_multiple_alignments(bamfile):

        # Check if all alignments in the bundle are below the threshold
        read_expression = int(next(iter(bundle)).read.name.split("_x")[1])  # Extract once, since all are identical

        if read_expression < args.reads_threshold:
            continue  # Skip the entire bundle if the read expression is too low

        count_alignment = False

        # Go over every alignment in the bundle (=iterator over multiple alignments of one specific read)
        for almnt in bundle:

            if almnt.aligned:
                # print(almnt) <SAM_Alignment object: Read 'seq_581927_x1' aligned to KI270713.1:[31671,31706)/->
                # print(almnt.iv) chr8:[135284304,135284320)/-
                # print(almnt.iv.start) 135284304 => 0-based, in BAM it is 135284305
                # print(almnt.iv.end) 135284320
                count_alignment = True

                seqs = str(almnt.read)

                read_start = min(almnt.iv.start, almnt.iv.end)
                read_end = max(almnt.iv.start, almnt.iv.end)
                # read_iv = HTSeq.GenomicInterval(almnt.iv.chrom, read_start, read_end, ".")

                for iv, val in trna[almnt.iv].steps():
                    feat_start = min(iv.start, iv.end)
                    feat_end = max(iv.start, iv.end)
                    overlap_length = max(0, min(read_end, feat_end) - max(read_start, feat_start))
                    
                    for feature in val:
                        read_overlaps_trna[seqs][feature].append(overlap_length) 

                for iv, val in snorna[almnt.iv].steps():
                    feat_start = min(iv.start, iv.end)
                    feat_end = max(iv.start, iv.end)
                    overlap_length = max(0, min(read_end, feat_end) - max(read_start, feat_start))

                    # Store overlaps for each feature in the set
                    for feature in val:
                        read_overlaps_snorna[seqs][feature].append(overlap_length)

                for iv, val in srna[almnt.iv].steps():
                    feat_start = min(iv.start, iv.end)
                    feat_end = max(iv.start, iv.end)
                    overlap_length = max(0, min(read_end, feat_end) - max(read_start, feat_start))

                    # Store overlaps for each feature in the set
                    for feature in val:
                        read_overlaps_srna[seqs][feature].append(overlap_length) 

                for iv, val in pirna[almnt.iv].steps():
                    feat_start = min(iv.start, iv.end)
                    feat_end = max(iv.start, iv.end)
                    overlap_length = max(0, min(read_end, feat_end) - max(read_start, feat_start))

                    # Store overlaps for each feature in the set
                    for feature in val:
                        read_overlaps_pirna[seqs][feature].append(overlap_length)         

                for iv, val in mrna[almnt.iv].steps():
                    feat_start = min(iv.start, iv.end)
                    feat_end = max(iv.start, iv.end)
                    overlap_length = max(0, min(read_end, feat_end) - max(read_start, feat_start))

                    # Store overlaps for each feature in the set
                    for feature in val:
                        read_overlaps_mrna[seqs][feature].append(overlap_length)

                for iv, val in lncrna[almnt.iv].steps():
                    feat_start = min(iv.start, iv.end)
                    feat_end = max(iv.start, iv.end)
                    overlap_length = max(0, min(read_end, feat_end) - max(read_start, feat_start))

                    # Store overlaps for each feature in the set
                    for feature in val:
                        read_overlaps_lncrna[seqs][feature].append(overlap_length)

                multimappings[seqs] = int(almnt.optional_field("NH"))


        if count_alignment:
            counts[seqs] = read_expression

    logging.info("Counting ended.")

    # -------------------------------------------------------------------------
    # Post-processing: filtering and merging
    # -------------------------------------------------------------------------
    logging.info("Filtering features by overlap...")

    # Prepare intermediate dicts
    def to_result_dict(overlaps):
        return {seq: [{f: ov} for f, ov in feats.items()] for seq, feats in overlaps.items()}

    final_result_pirna = to_result_dict(read_overlaps_pirna)
    final_result_trna = to_result_dict(read_overlaps_trna)
    final_result_snorna = to_result_dict(read_overlaps_snorna)
    final_result_srna = to_result_dict(read_overlaps_srna)
    final_result_mrna = to_result_dict(read_overlaps_mrna)
    final_result_lncrna = to_result_dict(read_overlaps_lncrna)


    # Apply overlap filtering
    filtered_results = {
        "pirna": filter_features_by_overlap(final_result_pirna, args.overlap_bp, args.overlap_frac),
        "trna": filter_features_by_overlap(final_result_trna, args.overlap_bp, args.overlap_frac),
        "snorna": filter_features_by_overlap(final_result_snorna, args.overlap_bp, args.overlap_frac),
        "other_sncrna": filter_features_by_overlap(final_result_srna, args.overlap_bp, args.overlap_frac),
        "mrna": filter_features_by_overlap(final_result_mrna, args.overlap_bp, args.overlap_frac),
        "lncrna": filter_features_by_overlap(final_result_lncrna, args.overlap_bp, args.overlap_frac),
    }

    # Convert to DataFrames
    dfs = [
        pd.DataFrame(counts.items(), columns=["sequence", "expression"]),
        *(convert_to_dataframe(filtered_results[k], k) for k in filtered_results.keys()),
        pd.DataFrame(multimappings.items(), columns=["sequence", "genome_alignments"]),
    ]

    # Merge the DataFrames
    merged_df = dfs[0]
    for df in dfs[1:]:
        merged_df = pd.merge(merged_df, df, on='sequence', how='outer')
    merged_df.fillna('', inplace=True)

    # Add MINTplates    
    merged_df = add_mint_plates(merged_df)

    # sort genes inside annotation columns
    columns_to_process = ['pirna', 'snorna', 'other_sncrna', 'trna', 'mrna', 'lncrna']

    # Apply sorting function to each column
    for col in columns_to_process:
        merged_df[col] = merged_df[col].apply(sort_genes)

    # -------------------------------------------------------------------------
    # Output
    # -------------------------------------------------------------------------
    # Prepare output file
    input_bam_filename = os.path.splitext(os.path.basename(args.input_bam))[0]
    output_basename = args.sample_name or input_bam_filename.replace(".bam", "")
    if output_basename.endswith("."):
        output_basename = output_basename[:-1]
    
    output_path = os.path.join(args.output_dir, output_basename) if args.output_dir else output_basename

    if args.merge_identical:
        logging.info("Merging sequences with identical annotations...")
        df_final = merge_identical_loci(merged_df)
        out_file = f"{output_path}.short_rna_counts_merged.tsv"
        df_final.to_csv(out_file, index=False, sep="\t")
    else:
        out_file = f"{output_path}.short_rna_counts.tsv"
        merged_df.to_csv(out_file, index=False, sep="\t")

    logging.info("Wrote file: %s", out_file)
    logging.info("Execution finished in %.2f seconds.", time.time() - start_time)


if __name__ == "__main__":
    main()

