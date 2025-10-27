import subprocess
import pandas as pd
import re
import numpy as np
import HTSeq

from MINTplates_module import *


################################################################
# ANNOTATION UTILS
################################################################
def _parse_gencode_gtf(gtf_file):
    output_file = gtf_file + ".tmp"
    awk_command = f"awk -F'\\t' '$3 ~ /gene/ {{print}}' {gtf_file} > {output_file}"
    subprocess.run(awk_command, shell=True, check=True)
    return output_file


def _iterate_itertuples(df, output_array):
    for row in df.itertuples(index=False):
        feature = HTSeq.GenomicInterval(str(row.seqname), row.start - 1, row.end, row.strand)
        # feature = HTSeq.GenomicInterval(str(row.chr), row.start, row.end, row.strand)
        # genes[feature] += row.attributes.split(";")[0].split(" ")[1].strip('";')
        output_array[feature] += row.gene_id
    return output_array


def read_gtf(gtf_file):
    new_gtf_list = []
    new_gtf_list.append(_parse_gencode_gtf(gtf_file))
    dataframes = []
    for gtf_file in new_gtf_list:
        df = pd.read_csv(gtf_file, sep='\t', header=None, comment='#')
        df.columns = ['seqname', 'source', 'feature', 'start', 'end', 'score', 'strand', 'frame', 'attribute']
        fields = ['gene_id', 'gene_name', 'gene_type']
        for field in fields:
            df[field] = df['attribute'].apply(lambda x: re.findall(rf'{field} "([^"]*)"', x)[0] if rf'{field} "' in x else '')
        df.replace('', np.nan, inplace=True)
        df.drop('attribute', axis=1, inplace=True)
        dataframes.append(df)
    combined_df = pd.concat(dataframes, ignore_index=True)
    return combined_df


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


################################################################
# QUANTIFICATION UTILS
################################################################
def parse_rna_classes(input_gtf):
    """Function to read GTF file and divide it into tables based on RNA class"""
    combined_df = read_gtf(input_gtf)
    # selecting only gene features
    gene_df = combined_df[combined_df['feature'] == "gene"]
    # dividing GTF file into separate dataframes for each RNA class
    trna_df = gene_df[gene_df['gene_type'] == "tRNA"]
    snorna_df = gene_df[gene_df['gene_type'] == "snoRNA"]
    srna_df = gene_df[gene_df['gene_type'].isin(["scaRNA", "snRNA", "scRNA", "sRNA", "misc_RNA"])]
    pirna_df = gene_df[gene_df['gene_type'] == "piRNA"]
    mrna_df = gene_df[gene_df['gene_type'] == "protein_coding"]
    lncrna_df = gene_df[gene_df['gene_type'].isin(["lncRNA",
                                                   "processed_pseudogene",
                                                   "unprocessed_pseudogene",
                                                   "transcribed_processed_pseudogene",
                                                   "transcribed_unitary_pseudogene",
                                                   "transcribed_unprocessed_pseudogene",
                                                   "translated_processed_pseudogene",
                                                   "unitary_pseudogene"])]
    #other_df = gene_df[~gene_df['gene_type'].isin(["tRNA", "Mt_tRNA", "snoRNA", "piRNA", "protein_coding", "lncRNA"])]
    return gene_df, trna_df, snorna_df, srna_df, pirna_df, mrna_df, lncrna_df


def parse_gtf_for_quantification(gene_df, trna_df, snorna_df, srna_df, pirna_df, mrna_df, lncrna_df, stranded=False):
    """Function to parse RNA classes into separate HTSeq objects (HTSeq.GenomicArrayOfSets)"""
    # Create HTSeq.GenomicArrayOfSets objects for each dataframe dynamically
    arrays = {}
    for df_name, df in zip(['genes', 'trna', 'snorna', 'other_sncrna', 'pirna', 'mrna', 'lncrna'], 
                           [gene_df, trna_df, snorna_df, srna_df, pirna_df, mrna_df, lncrna_df]):
        arrays[df_name] = HTSeq.GenomicArrayOfSets("auto", stranded=stranded)
        _iterate_itertuples(df, arrays[df_name])
    return arrays


# tag = '2A10G29'
# return = ['2', 'A', '10', 'G', '29']
def parse_tag(tag):
    """Split MD:Z tag into a list"""
    pattern = re.compile(r'(\d+|\D+)')
    result = pattern.findall(tag)
    return result 


# Function to sort genes in a cell -> to sort gene names inside columns like pirna, snorna,....
def sort_genes(cell):
    if pd.isna(cell):  # Skip NaN values
        return cell
    genes = [gene.strip() for gene in cell.split(',')]
    genes.sort()
    return ','.join(genes)


def filter_features_by_overlap(final_result, bp_threshold=5, frac_threshold=None):
    """
    Filter features for each sequence based on the total overlap length with genomic annotations.

    Parameters
    ----------
    final_result : dict
        Dictionary mapping sequences (str) to lists of feature–overlap mappings.
        Example structure:
            {
                'UGAGGUAGUAGGUUGUAUAGU': [
                    {'piRNA_123': [10, 8]},
                    {'piRNA_456': [5]}
                ],
                ...
            }

        Each inner list item is a dict mapping one feature name to a list of overlap lengths
        (in base pairs) for that sequence.

    bp_threshold :  Minimum total number of overlapping base pairs required for a feature to be retained.

    frac_threshold : Minimum fraction of the sequence length that must overlap the feature.
                     If provided, the effective threshold will be the maximum of the absolute
                     `bp_threshold` and the fractional one. Default is None (ignored).
    """
    filtered = {}

    for seq, features in final_result.items():
        # Determine the required overlap length (in bp) for this sequence.
        need = bp_threshold
        if frac_threshold is not None:
            # Compute fractional requirement: ceil(frac * read_length)
            # and take the stricter (larger) of the two thresholds.
            need = max(need, int(np.ceil(frac_threshold * len(seq))))

        kept = []  # Store features that pass the threshold for this sequence

        # Each `features` element is a dictionary like {'feature_id': [list_of_overlap_lengths]}
        for feature_dict in features:
            for feat, overlaps in feature_dict.items():
                total_overlap = sum(overlaps)
                # Keep this feature if total overlap ≥ threshold
                if total_overlap >= need:
                    kept.append({feat: overlaps})

        # Only add the sequence if it has at least one valid feature
        if kept:
            filtered[seq] = kept

    return filtered


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