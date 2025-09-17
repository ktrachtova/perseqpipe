import subprocess
import pandas as pd
import re
import numpy as np
import HTSeq

# source activate /mnt/ssd/ssd_1/conda_envs/kaja_rna_quantification
# python parse_reference_gtfs.py /mnt/nfs/home/422653/000000-My_Documents/smallRNA-Seq/smallRNA-seq/data/reference/gencode.v43.pirna.trna.snorna.gtf
def _parse_gencode_gtf(gtf_file):
    output_file = gtf_file + ".tmp"
    awk_command = f"awk -F'\\t' '$3 ~ /gene/ {{print}}' {gtf_file} > {output_file}"
    subprocess.run(awk_command, shell=True, check=True)
    return output_file

def read_gtf(gtf_list):
    new_gtf_list = []
    for gtf_file in gtf_list:
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
        #gr = pr.read_gtf(gtf_file)
        #df = gr.df
        #df = df[['Chromosome','Feature','Start','End','Strand','gene_id','gene_name','gene_type']]
        dataframes.append(df)
    combined_df = pd.concat(dataframes, ignore_index=True)
    return combined_df

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


def _iterate_itertuples(df, output_array):
    for row in df.itertuples(index=False):
        feature = HTSeq.GenomicInterval(str(row.seqname), row.start - 1, row.end, row.strand)
        # feature = HTSeq.GenomicInterval(str(row.chr), row.start, row.end, row.strand)
        # genes[feature] += row.attributes.split(";")[0].split(" ")[1].strip('";')
        output_array[feature] += row.gene_id
    return output_array


def parse_gtf_for_quantification(gene_df, trna_df, snorna_df, srna_df, pirna_df, mrna_df, lncrna_df, stranded=False):
    """Function to parse RNA classes into separate HTSeq objects (HTSeq.GenomicArrayOfSets)"""
    # Create HTSeq.GenomicArrayOfSets objects for each dataframe dynamically
    arrays = {}
    for df_name, df in zip(['genes', 'trna', 'snorna', 'srna', 'pirna', 'mrna', 'lncrna'], 
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