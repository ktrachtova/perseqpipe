#!/usr/bin/env python3

import os
import pandas as pd
import re
import argparse

# Define patterns globally so they can be accessed in multiple functions
patterns = [
    (r'\.ad3trim\.collapsed\.ad3trim\.counts\.txt$', "adapt2_trim_reads"),
    (r'\.ad3trim\.collapsed\.ad3short\.counts\.txt$', "adapt2_short_reads"),
    (r'\.ad3trim\.collapsed\.ad3untrim\.counts\.txt$', "adapt2_untrim_reads"),
    (r'\.ad3trim\.counts\.txt$', "adapt1_trim_reads"),
    (r'\.ad3short\.counts\.txt$', "adapt1_short_reads"),
    (r'\.ad3untrim\.counts\.txt$', "adapt1_untrim_reads"),
    (r'\.ad3trim\.r4trim\.counts\.txt$', "r4base_trim_reads"),
    (r'\.collapsed\.counts\.txt$', "collapsed_reads"),
    (r'\.rrna\.multi\.counts\.txt$', "rrna_multimapped_reads"),
    (r'\.rrna\.uniq\.counts\.txt$', "rrna_unique_reads"),
    (r'\.rrna\.unmapped\.counts\.txt$', "rrna_unmapped_reads"),
    (r'\.mirna\.mapped\.counts\.txt$', "mirna_mapped_reads"),
    (r'\.mirna\.unmapped\.counts\.txt$', "mirna_unmapped_reads"),
    (r'\.genome\.multi\.counts\.txt$', "genome_multimapped_reads"),
    (r'\.genome\.uniq\.counts\.txt$', "genome_unique_reads"),
    (r'\.genome\.unmapped\.counts\.txt$', "genome_unmapped_reads"),
    (r'\.counts\.txt$', "raw_reads"),  # This should be last to avoid premature matching
]

patterns_sort = [
    (r'\.ad3trim\.counts\.txt$', "adapt1_trim_reads"),
    (r'\.ad3short\.counts\.txt$', "adapt1_short_reads"),
    (r'\.ad3untrim\.counts\.txt$', "adapt1_untrim_reads"),
    (r'\.ad3trim\.r4trim\.counts\.txt$', "r4base_trim_reads"),
    (r'\.collapsed\.counts\.txt$', "collapsed_reads"),
    (r'\.ad3trim\.collapsed\.ad3trim\.counts\.txt$', "adapt2_trim_reads"),
    (r'\.ad3trim\.collapsed\.ad3short\.counts\.txt$', "adapt2_short_reads"),
    (r'\.ad3trim\.collapsed\.ad3untrim\.counts\.txt$', "adapt2_untrim_reads"),
    (r'\.rrna\.multi\.counts\.txt$', "rrna_multimapped_reads"),
    (r'\.rrna\.uniq\.counts\.txt$', "rrna_unique_reads"),
    (r'\.rrna\.unmapped\.counts\.txt$', "rrna_unmapped_reads"),
    (r'\.mirna\.mapped\.counts\.txt$', "mirna_mapped_reads"),
    (r'\.mirna\.unmapped\.counts\.txt$', "mirna_unmapped_reads"),
    (r'\.genome\.multi\.counts\.txt$', "genome_multimapped_reads"),
    (r'\.genome\.uniq\.counts\.txt$', "genome_unique_reads"),
    (r'\.genome\.unmapped\.counts\.txt$', "genome_unmapped_reads"),
    (r'\.counts\.txt$', "raw_reads"),  # This should be last to avoid premature matching
]

def extract_sample_name(filename):
    """Extracts the sample name from the filename by removing known suffixes."""
    sample_name = re.split(r'\.counts\.txt$', filename)[0]
    sample_name = re.sub(r'\.(ad3trim|ad3short|ad3untrim|r4trim|collapsed|ad3trim\.collapsed\.ad3trim|ad3trim\.collapsed\.ad3short|ad3trim\.collapsed\.ad3untrim|rrna\.multi|rrna\.uniq|rrna\.unmapped|mirna\.mapped|mirna\.unmapped|genome\.multi|genome\.uniq|genome\.unmapped)', '', sample_name)
    return sample_name

def determine_category(filename):
    """Maps filename to category name based on known patterns."""
    for pattern, category in patterns:
        if re.search(pattern, filename):
            return category
    return None

def read_counts_from_file(filepath):
    """Reads the first line from a file and extracts the read count as an integer."""
    try:
        with open(filepath, 'r') as f:
            return int(f.readline().strip())
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        return None

def process_directory(input_dir):
    """Processes all count files in the input directory and aggregates read counts per sample."""
    data = {}
    
    for filename in os.listdir(input_dir):
        if filename.endswith(".counts.txt"):
            sample_name = extract_sample_name(filename)
            category = determine_category(filename)
            if category is None:
                continue
            
            count = read_counts_from_file(os.path.join(input_dir, filename))
            print(filename, sample_name, category, count)
            if count is not None:
                if sample_name not in data:
                    data[sample_name] = {}
                data[sample_name][category] = count

    print(data)    
    df = pd.DataFrame.from_dict(data, orient='index').fillna(0).astype(int)
    df.index.name = "sample"
    df.reset_index(inplace=True)
    
    # Compute percentages
    dependencies = {
        "adapt1_trim_reads": "raw_reads",
        "adapt1_short_reads": "raw_reads",
        "adapt1_untrim_reads": "raw_reads",
        "r4base_trim_reads": "raw_reads",
        "collapsed_reads": "raw_reads",
        "adapt2_trim_reads": "raw_reads",
        "adapt2_short_reads": "raw_reads",
        "adapt2_untrim_reads": "raw_reads",
        "rrna_multimapped_reads": "adapt2_trim_reads",
        "rrna_unique_reads": "adapt2_trim_reads",
        "rrna_unmapped_reads": "adapt2_trim_reads",
        "mirna_mapped_reads": "rrna_unmapped_reads",
        "mirna_unmapped_reads": "rrna_unmapped_reads",
        "genome_multimapped_reads": "mirna_unmapped_reads",
        "genome_unique_reads": "mirna_unmapped_reads",
        "genome_unmapped_reads": "mirna_unmapped_reads",
    }
    
    if "adapt2_trim_reads" not in df.columns:
        dependencies = {k: ("adapt1_trim_reads" if v == "adapt2_trim_reads" else v) for k, v in dependencies.items()}
    
    for col, start_col in dependencies.items():
        if col in df.columns and start_col in df.columns:
            df[col + "_%"] = (df[col] / df[start_col] * 100).round(2).fillna(0)
    
    # Define the column order
    ordered_columns = ["sample", "raw_reads"]
    for _, col in patterns_sort:
        if col in df.columns and col != "raw_reads":
            ordered_columns.append(col)
            if col + "_%" in df.columns:
                ordered_columns.append(col + "_%")
    
    df = df[ordered_columns]
    
    return df

def main():
    parser = argparse.ArgumentParser(description="Process read count files in a directory.")
    parser.add_argument("input_directory", type=str, help="Path to the directory containing count files")
    args = parser.parse_args()
    
    output_file = "read_counts_summary.csv"
    
    df = process_directory(args.input_directory)
    df.to_csv(output_file, index=False)
    print(f"Summary saved to {output_file}")

if __name__ == "__main__":
    main()
