#!/bin/bash
#
# Module 1: FirstQC -> FastQC
#
###############################
# Input: $1=fastq_file $2=output_directory $3=threads

input_file=$1
output_dir=$2
threads=$3

fastqc --threads $threads -o $output_dir "$input_file"

# calculate number of reads in FASTQ file
# echo $(zcat $input_file | wc -l)/4|bc > ${input_file%.fastq.gz}.counts.txt
echo $(( $(zcat $input_file | wc -l) / 4 )) > ${input_file%.fastq.gz}.counts.txt

# DEPRECATED:
# seqkit stats $input_file --basename --all -T > ${input_file%.fastq.gz}.run_statistics.txt
# mv ${input_file%.fastq.gz}.reads_statistics.txt $output_dir
