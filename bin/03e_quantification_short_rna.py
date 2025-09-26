#!/usr/bin/env python3

import HTSeq
import pandas as pd
import time
import collections
import argparse
import logging
import os
from collections import defaultdict

from MINTplates_module import *
from utils import *

# input_gtf = ['gencode.v47.annotation.gtf', 'piRNA_db_custom_genomeMap.gtf', 'snoRNA_db_custom_genomeMap.gtf', 'tRNA_db_custom_genomeMap.gtf']
# source activate /mnt/ssd/ssd_1/conda_envs/kaja_rna_quantification
# python quantify_v8.py /mnt/nfs/home/422653/000000-My_Documents/smallRNA-Seq/pipeline_dev/mock_project_v8_franta_pirna/rna_quantification/genome_star/alignment/4NC1.genome.Aligned.sortedByCoord.out.filtered.bam /mnt/nfs/home/422653/000000-My_Documents/smallRNA-Seq/smallRNA-seq/data/reference/gencode.v43.pirna.trna.snorna.gtf merge

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s', datefmt='%d/%m/%Y:%H:%M')


# Function to sort genes in a cell -> to sort gene names inside columns like pirna, snorna,....
def sort_genes(cell):
    if pd.isna(cell):  # Skip NaN values
        return cell
    genes = [gene.strip() for gene in cell.split(',')]
    genes.sort()
    return ','.join(genes)


def merge_dfs_on_sequence(dfs):
    """
    Merges multiple DataFrames on the 'Sequence' column and fills missing values with an empty string.
    
    Parameters:
    - dfs (list of pd.DataFrame): List of DataFrames to merge.
    
    Returns:
    - pd.DataFrame: Merged DataFrame with sequences as rows and feature columns.
    """
    # Start merging with the first DataFrame
    merged_df = dfs[0]
    
    # Merge the remaining DataFrames one by one on 'Sequence'
    for df in dfs[1:]:
        merged_df = pd.merge(merged_df, df, on='sequence', how='outer')
    
    # Fill any missing values with an empty string
    merged_df.fillna('', inplace=True)
    
    return merged_df


def filter_features_by_overlap(final_result, overlap_threshold):
    """
    Filters features for each sequence in the final_result based on a minimum overlap threshold.
    
    Parameters:
    - final_result (dict): A dictionary with sequences as keys and a list of feature-overlap pairs as values.
    - overlap_threshold (int): The minimum total overlap for a feature to be included in the result.
    
    Returns:
    - dict: A filtered dictionary with sequences and features whose total overlap >= threshold.
    """
    filtered_results = {}

    for seq, features in final_result.items():
        filtered_features = []
        
        for feature_dict in features:
            for feature, overlaps in feature_dict.items():
                total_overlap = sum(overlaps)
                
                # Include feature if total_overlap is greater than or equal to the threshold
                if total_overlap >= overlap_threshold:
                    filtered_features.append({feature: overlaps})
        
        # Only add to the result if there are any valid features
        if filtered_features:
            filtered_results[seq] = filtered_features

    return filtered_results


def convert_to_dataframe(filtered_results, feature_name):
    """
    Converts the filtered results into a pandas DataFrame where rows are sequences 
    and columns are a comma-separated list of features.
    
    Parameters:
    - filtered_results (dict): A dictionary with sequences as keys and a list of feature-overlap pairs as values.
    
    Returns:
    - pd.DataFrame: A DataFrame with sequences as rows and comma-separated list of features as columns.
    """
    # Initialize a list to store rows for the DataFrame
    data = []
    
    # Iterate over filtered_results to create rows
    for seq, features in filtered_results.items():
        # Extract feature names from the list of feature dictionaries
        feature_names = [list(feature.keys())[0] for feature in features]
        
        # Join feature names with commas to create a single string
        feature_list = ','.join(feature_names)
        
        # Append the sequence and its features to the data list
        data.append([seq, feature_list])
    
    # Create the DataFrame
    df = pd.DataFrame(data, columns=['sequence', feature_name])
    
    return df


def add_mint_plates(df):
    """
    Add MINT licence plates for every sequence (https://cm.jefferson.edu/license-plates-download/)
    
    INPUT: DataFrame where index is a sequence

    OUTPUT: DataFrame with added column with licence plates
    """

    mint_plates = []
    # go over rownames/index of the data frame and add licence plate
    # by default, 'seq' is added as a prefix
    for sequence in df['sequence']:
        mint_plates.append(run_as_script(sequence, 'en', 'seq'))
    df['MINT_plate'] = mint_plates
    return df

# run_as_script(
#    "AACTTAACTTGACCGCTCTGAC", 'en',
#    'tRF')


def merge_identical_loci(df_final):
    """
    Merges expression of sequences with identical annotations.
    
    This function takes a DataFrame as input containing sequence counts and annotations,
    and merges sequences that have identical annotations, combining their expression counts.
    
    Parameters:
        df_final (DataFrame): Input DataFrame containing sequence counts and annotations.
        
    Returns:
        DataFrame: DataFrame with merged sequences and combined expression counts.
    """

    # Create a unique identifier for each group based on index and expression
    df_final['grouped_seq'] = df_final.apply(lambda row: f"{row['index']}_{row['expression']}", axis=1)

    # List of columns representing different types of annotations
    annotation_columns = ['mrna', 'lncrna', 'snorna', 'trna', 'pirna']

    # Extract rows without any annotation -> we do not want to merge these!
    empty_rows = df_final[df_final[annotation_columns].apply(lambda row: all(not bool(x) for x in row), axis=1)]

    # Remove rows without any annotation from the table
    df_final = df_final[df_final[annotation_columns].apply(lambda row: any(bool(x) for x in row), axis=1)]

    # Convert annotation columns to lists
    for col in annotation_columns:
        df_final[col] = df_final[col].apply(lambda x: x.split(','))
        df_final[f'{col}_tuple'] = df_final[col].apply(tuple)

    # Group columns for merging based on annotation tuples
    group_columns = [f'{col}_tuple' for col in annotation_columns]

    # Group by the annotation tuples and aggregate the results
    result_df = df_final.groupby(group_columns, as_index=False).agg({
        'index': lambda x: max(x, key=len),
        'grouped_seq': lambda x: ','.join(x),
        'expression': 'sum'
    })

    # Convert back to lists from tuples
    for col in annotation_columns:
        result_df[col] = result_df[f'{col}_tuple'].apply(list)

    # Drop intermediate columns
    result_df.drop(columns=[f'{col}_tuple' for col in annotation_columns], inplace=True)

    # Concatenate the merged DataFrame with the rows without annotations
    final_result_df = pd.concat([result_df, empty_rows[['index','grouped_seq', 'expression', 'mrna', 'lncrna', 'snoRNA', 'tRNA', 'piRNA']]], ignore_index=True)

    return final_result_df


def _flatten(value):
    if isinstance(value, (list, set)):
        return ','.join(value)
    return value


def main():

    start_time = time.time()
    logging.info("Script execution started.")

    def parse_gtf_list(value):
        """
        Splits the input string of comma-separated GTF file paths into a list.
        """
        return value.split(',')

    parser = argparse.ArgumentParser(description="Script for counting short sequences from small RNA sequencing data.")
    parser.add_argument("input_bam", help="Input BAM file")
    parser.add_argument("input_gtf", type=parse_gtf_list, help="Comma-separated list of GTF files with annotations")
    parser.add_argument("--merge_identical", action="store_true", help="Merge sequences with identical annotations")
    parser.add_argument("--sample_name", help="Sample name for output files (optional)")
    parser.add_argument("--output_dir", help="Output directory (optional)")
    parser.add_argument("--reads_threshold",
                        type=int,
                        help="Reads thresholds, any read with expression lower than this value will not be counted, default 1 (all reads are counted)",
                        default=1)

    args = parser.parse_args()

    # Load BAM file
    bamfile = HTSeq.BAM_Reader(args.input_bam)

    # Load GTF with annotations
    logging.info("Reading the GTF file(s)...")
    gene_df, trna_df, snorna_df, srna_df, pirna_df, mrna_df, lncrna_df = parse_rna_classes(args.input_gtf)
    logging.info("Reading GTF(s) %s ended.", args.input_gtf)


    # Parse GTF file into HTSeq objects used during quantification
    logging.info("Parsing the GTF file...")
    rna_arrays = parse_gtf_for_quantification(gene_df, trna_df, snorna_df, srna_df, pirna_df, mrna_df, lncrna_df)
    logging.info("Parsing GTF %s ended.", args.input_gtf)

    trna = rna_arrays['trna']
    snorna = rna_arrays['snorna']
    srna = rna_arrays['srna']
    pirna = rna_arrays['pirna']
    mrna = rna_arrays['mrna']
    lncrna = rna_arrays['lncrna']

    # Prepare collections for counting sequences for individual RNA classes
    counts = collections.Counter()

    multimappings = collections.Counter()

    logging.info("Counting reads...")

    read_overlaps_trna = defaultdict(lambda: defaultdict(list))
    read_overlaps_pirna = defaultdict(lambda: defaultdict(list))
    read_overlaps_snorna = defaultdict(lambda: defaultdict(list))
    read_overlaps_srna = defaultdict(lambda: defaultdict(list))
    read_overlaps_mrna = defaultdict(lambda: defaultdict(list))
    read_overlaps_lncrna = defaultdict(lambda: defaultdict(list))

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
                read_iv = HTSeq.GenomicInterval(almnt.iv.chrom, read_start, read_end, ".")

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
            counts[seqs] = int(almnt.read.name.split("_x")[1])

    logging.info("Counting ended.")
    logging.info("Writing counts...")
    # write_counts(counts, annotations, df)

    final_result_pirna = {seq: [{feat: overlaps} for feat, overlaps in features.items()] for seq, features in read_overlaps_pirna.items()}
    final_result_snorna = {seq: [{feat: overlaps} for feat, overlaps in features.items()] for seq, features in read_overlaps_snorna.items()}
    final_result_srna = {seq: [{feat: overlaps} for feat, overlaps in features.items()] for seq, features in read_overlaps_srna.items()}
    final_result_trna = {seq: [{feat: overlaps} for feat, overlaps in features.items()] for seq, features in read_overlaps_trna.items()}
    final_result_mrna = {seq: [{feat: overlaps} for feat, overlaps in features.items()] for seq, features in read_overlaps_mrna.items()}
    final_result_lncrna = {seq: [{feat: overlaps} for feat, overlaps in features.items()] for seq, features in read_overlaps_lncrna.items()}

    overlap_threshold = 5
    filtered_results_pirna = filter_features_by_overlap(final_result_pirna, overlap_threshold)
    filtered_results_trna = filter_features_by_overlap(final_result_trna, overlap_threshold)
    filtered_results_snorna = filter_features_by_overlap(final_result_snorna, overlap_threshold)
    filtered_results_srna = filter_features_by_overlap(final_result_srna, overlap_threshold)
    filtered_results_mrna = filter_features_by_overlap(final_result_mrna, overlap_threshold)
    filtered_results_lncrna = filter_features_by_overlap(final_result_lncrna, overlap_threshold)

    df_pirna = convert_to_dataframe(filtered_results_pirna, 'pirna')
    df_trna = convert_to_dataframe(filtered_results_trna, 'trna')
    df_snorna = convert_to_dataframe(filtered_results_snorna, 'snorna')
    df_srna = convert_to_dataframe(filtered_results_srna, 'srna')
    df_mrna = convert_to_dataframe(filtered_results_mrna, 'mrna')
    df_lncrna = convert_to_dataframe(filtered_results_lncrna, 'lncrna')

    df_multimappings = pd.DataFrame(multimappings.items(), columns=['sequence', 'genome_alignments'])
    df_counts = pd.DataFrame(counts.items(), columns=['sequence', 'expression'])

    # List of DataFrames
    dfs = [df_counts, df_pirna, df_trna, df_snorna, df_srna, df_mrna, df_lncrna, df_multimappings]

    # Merge the DataFrames
    merged_df = merge_dfs_on_sequence(dfs)
    
    merged_df = add_mint_plates(merged_df)

    # sort genes inside annotation columns
    columns_to_process = ['pirna', 'snorna', 'srna', 'trna', 'mrna', 'lncrna']

    # Apply sorting function to each column
    for col in columns_to_process:
        merged_df[col] = merged_df[col].apply(sort_genes)

    # Prepare output file
    input_bam_filename = os.path.splitext(os.path.basename(args.input_bam))[0]
    # If sample_name parameter specified
    if args.sample_name:
        # if user gave sample_name endind with '.', remove it
        if args.sample_name.endswith('.'):
            output_filename = args.sample_name[:-1]
        else:
            output_filename = args.sample_name
    # If no parameter sample_name given, just strip '.bam' from the input file and use the rest as output file name
    else:
        output_filename = input_bam_filename.replace('.bam', '')

    # Determine the output file path
    if args.output_dir:
        output_file_path = os.path.join(args.output_dir, output_filename)
    else:
        output_file_path = output_filename
    
    if args.merge_identical:
        logging.info("Merging expression of sequences with identical annotations...")
        df_final = merge_identical_loci(merged_df)
        df_final.to_csv(output_file_path + ".short_rna_counts_merged.tsv", index=False, sep="\t")
        logging.info("Wrote file: " +  output_file_path + ".short_rna_counts_merged.tsv")
    else:
        merged_df.to_csv(output_file_path + ".short_rna_counts.tsv", index=False, sep="\t")
        logging.info("Wrote file: " +  output_file_path + ".short_rna_counts.tsv")

    logging.info("Writing counts ended.")
    logging.info("Script execution ended in %s seconds.", time.time() - start_time)


if __name__ == "__main__":
    main()

