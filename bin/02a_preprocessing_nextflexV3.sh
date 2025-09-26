#!/bin/bash
#
# Cleaning smallRNA-seq data - Nextflex V3
#
# Requires Cutadapt, fastx-toolkit, FastQC, multiQC
#
set -euo pipefail

SAMPLE=$1
THREADS=$2

# Trimming parameters
# Specify default values in case this script is being used out of the nextflow pipeline
ERROR_RATE=${3:-0.10}                       # Allowed error rate or adapters
MIN_OVERLAP=${4:-5}                         # Minimal overlap of adapter for first adapter trimming; cutadapt uses this overlap as a "seed" and then tries to align the rest of the adapter. It doesn't remove the random hits in the middle of the sequence. We could go even lower if we would be interested in RNA/RNA fragments which could be approximately same length as the sequencing read length
DISC_SHORT=${5:-15}                         # Discard shorter reads
QUALITY_FILTER=${6:-10}                      # Quality filter for trimming
ADAPTER3_SEQ1=${7:-"TGGAATTCTCGGGTGCCAAGG"} # Default Truseq 3' adapter

echo "####################################################"
echo "Running PREPROCESSING MODULE for sample $SAMPLE"
echo "####################################################"
echo "Starting at $(date +%s)"
echo ""

####################################################################################################

APPENDIX=".fastq.gz" # Files suffix to launch the analysis on

QUALITY=33 #phred coding of input files

####################################################################################################

# Create a temporary directory for processing
mkdir -p ./intermediate_files/adapter1_trim
mkdir -p ./intermediate_files/adapter1_trim/discarded
mkdir -p ./intermediate_files/adapter1_trim/len_distributions
mkdir -p ./intermediate_files/r4base_trim
mkdir -p ./intermediate_files/r4base_trim/len_distributions

####################################################################################################
### PART 1: First adapter trimming - main indexed adapter

echo "PART 1: adapter trimming of the rightmost 3' adapter"
echo "####################################################"

echo "$(date +%s) Started trimming sample $SAMPLE"

cutadapt -a $ADAPTER3_SEQ1 \
         --times 1 \
	 --max-n=0 \
         -q $QUALITY_FILTER \
         -e $ERROR_RATE \
         -O $MIN_OVERLAP \
         -m $DISC_SHORT \
         -j $THREADS \
	     -o ./intermediate_files/adapter1_trim/${SAMPLE%.fastq*}.ad3trim.fastq.gz \
         --untrimmed-output=./intermediate_files/adapter1_trim/discarded/${SAMPLE%.fastq*}.ad3untrim.fastq.gz \
         --too-short-output=./intermediate_files/adapter1_trim/discarded/${SAMPLE%.fastq*}.ad3short.fastq.gz \
         $SAMPLE 2>&1 | tee -a ./intermediate_files/adapter1_trim/${SAMPLE%.fastq*}.cutadapt.txt

zcat ./intermediate_files/adapter1_trim/${SAMPLE%.fastq*}.ad3trim.fastq.gz | awk '{if(NR%4==2) print NR"\t"$0"\t"length($0)}' | cut -f3 | sort | uniq -c > ./intermediate_files/adapter1_trim/len_distributions/${SAMPLE%.fastq*}.ad3trim.lenDist.txt
zcat ./intermediate_files/adapter1_trim/discarded/${SAMPLE%.fastq*}.ad3short.fastq.gz | awk '{if(NR%4==2) print NR"\t"$0"\t"length($0)}' | cut -f3 | sort | uniq -c > ./intermediate_files/adapter1_trim/len_distributions/${SAMPLE%.fastq*}.ad3short.lenDist.txt
zcat ./intermediate_files/adapter1_trim/discarded/${SAMPLE%.fastq*}.ad3untrim.fastq.gz | awk '{if(NR%4==2) print NR"\t"$0"\t"length($0)}' | cut -f3 | sort | uniq -c > ./intermediate_files/adapter1_trim/len_distributions/${SAMPLE%.fastq*}.ad3untrim.lenDist.txt

echo "$(date +%s) Finished trimming sample $SAMPLE"

####################################################################################################
### PART 2: Trimming first/last 4 bases from each read

echo "PART 2: Trimming first/last 4 bases from each read"
echo "####################################################"

echo "$(date +%s) Started r4 trimming sample $SAMPLE"

cutadapt -u 4 -u -4 \
        -o ./intermediate_files/r4base_trim/${SAMPLE%.fastq*}.ad3trim.r4trim.fastq.gz \
        ./intermediate_files/adapter1_trim/${SAMPLE%.fastq*}.ad3trim.fastq.gz 2>&1 | tee -a ./intermediate_files/r4base_trim/${SAMPLE%.fastq*}.cutadapt.txt # --match-rea>

zcat ./intermediate_files/r4base_trim/${SAMPLE%.fastq*}.ad3trim.r4trim.fastq.gz | awk '{if(NR%4==2) print NR"\t"$0"\t"length($0)}' | cut -f3 | sort | uniq -c > ./intermediate_files/r4base_trim/len_distributions/${SAMPLE%.fastq*}.ad3trim.r4trim.lenDist.txt


echo "$(date +%s) Finished r4 trimming sample $SAMPLE"

#echo "PART 3: Collapsing reads"
#echo "#######################################################"

echo "PART 3: Collapsing reads"
echo "####################################################"

echo "$(date +%s) Started collapsing reads for sample $SAMPLE"

gunzip -c ./intermediate_files/r4base_trim/$(basename $SAMPLE .fastq.gz).ad3trim.r4trim.fastq.gz | fastx_collapser -Q$QUALITY | reformat.sh qfake=40 in=stdin.fa out=stdout.fq > $(basename $SAMPLE .fastq.gz).cleaned.fastq

echo "$(date +%s) Finished collapsing sample $SAMPLE"

