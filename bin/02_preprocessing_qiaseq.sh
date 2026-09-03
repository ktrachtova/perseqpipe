#!/bin/bash
# @author: Karolina Trachtova
# @description: Script for cleaning smallRNA-seq data, specific for lib prep kit: QIAseq
# @dependencies: cutadapt, fastx-toolkit, bbmap
#
set -euo pipefail

# Prevent Java hsperfdata conflicts when running inside containers
export JAVA_TOOL_OPTIONS="-XX:+PerfDisableSharedMem"

SAMPLE=$1
THREADS=$2

echo "####################################################"
echo "Running PREPROCESSING MODULE for sample $SAMPLE"
echo "####################################################"
echo "Starting at $(date +%s)"
echo ""

########################################################

QUALITY=33 #phred coding of input files

########################################################

# Trimming parameters
# Specify default values in case this script is being used out of the nextflow pipeline
ERROR_RATE=${3:-0.10}                                   # Allowed error rate or adapters
MIN_OVERLAP=${4:-5}                                     # Minimal overlap of adapter for first adapter trimming; cutadapt uses this overlap as a "seed" and then tries to align the rest of the adapter. It doesn't remove the random hits in the middle of the sequence. We could go even lower if we would be interested in RNA/RNA fragments which could be approximately same length as the sequencing read length
DISC_SHORT=${5:-15}                                     # Discard shorter reads
QUALITY_FILTER=${6:-10}                                 # Quality filter for trimming
ADAPTER3_SEQ1=${7:-"AGATCGGAAGAGCACACGTCTGAACTCCAGTCA"} # Default Truseq 3' adapter
ADAPTER3_SEQ2=${8:-"AACTGTAGGCACCATCAAT"}               # QIAseq specific 3' adapter

########################################################

# Create a temporary directory for processing
mkdir -p ./intermediate_files/adapter1_trim
mkdir -p ./intermediate_files/adapter1_trim/discarded
mkdir -p ./intermediate_files/adapter1_trim/len_distributions
mkdir -p ./intermediate_files/collapsed
mkdir -p ./intermediate_files/adapter2_trim
mkdir -p ./intermediate_files/adapter2_trim/discarded

########################################################

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
         --too-short-output=./intermediate_files/adapter1_trim/discarded/${SAMPLE%.fastq*}.ad3short.fastq.gz \
         --untrimmed-output=./intermediate_files/adapter1_trim/discarded/${SAMPLE%.fastq*}.ad3untrim.fastq.gz \
         $SAMPLE 2>&1 | tee -a ./intermediate_files/adapter1_trim/${SAMPLE%.fastq*}.cutadapt.txt
	
echo "$(date +%s) Finished trimming sample $SAMPLE"

# collect length distribution information
zcat ./intermediate_files/adapter1_trim/${SAMPLE%.fastq*}.ad3trim.fastq.gz | awk '{if(NR%4==2) print NR"\t"$0"\t"length($0)}' | cut -f3 | sort | uniq -c > ./intermediate_files/adapter1_trim/len_distributions/${SAMPLE%.fastq*}.ad3trim.lenDist.txt
zcat ./intermediate_files/adapter1_trim/discarded/${SAMPLE%.fastq*}.ad3short.fastq.gz | awk '{if(NR%4==2) print NR"\t"$0"\t"length($0)}' | cut -f3 | sort | uniq -c > ./intermediate_files/adapter1_trim/len_distributions/${SAMPLE%.fastq*}.ad3short.lenDist.txt
zcat ./intermediate_files/adapter1_trim/discarded/${SAMPLE%.fastq*}.ad3untrim.fastq.gz | awk '{if(NR%4==2) print NR"\t"$0"\t"length($0)}' | cut -f3 | sort | uniq -c > ./intermediate_files/adapter1_trim/len_distributions/${SAMPLE%.fastq*}.ad3untrim.lenDist.txt

########################################################

echo "PART 2: collapsing reads"
echo "####################################################"

echo "$(date +%s) Started collapsing reads for sample $SAMPLE"

gunzip -c ./intermediate_files/adapter1_trim/${SAMPLE%.fastq*}.ad3trim.fastq.gz | fastx_collapser -Q$QUALITY | reformat.sh qfake=40 in=stdin.fa out=./intermediate_files/collapsed/$(basename $SAMPLE .fastq.gz).ad3trim.collapsed.fastq.gz

echo "$(date +%s) Finished collapsing sample $SAMPLE"

########################################################

echo "PART 3: Second adapter (QIAseq-specific) + UMI trimming"
echo "#######################################################"

echo "$(date +%s) Started second adapter + UMI trimming for sample $SAMPLE"

cutadapt -a $ADAPTER3_SEQ2 \
         --times 1 \
         -e $ERROR_RATE \
         -O $MIN_OVERLAP \
         -m $DISC_SHORT \
         -j $THREADS \
         -o ./intermediate_files/adapter2_trim/$(basename $SAMPLE .fastq.gz).ad3trim.collapsed.ad3trim.fastq.gz \
         --too-short-output=./intermediate_files/adapter2_trim/discarded/$(basename $SAMPLE .fastq.gz).ad3trim.collapsed.ad3short.fastq.gz \
         --untrimmed-output=./intermediate_files/adapter2_trim/discarded/$(basename $SAMPLE .fastq.gz).ad3trim.collapsed.ad3untrim.fastq.gz \
         ./intermediate_files/collapsed/$(basename $SAMPLE .fastq.gz).ad3trim.collapsed.fastq.gz 2>&1 | tee -a ./intermediate_files/collapsed/$(basename $SAMPLE .fastq.gz).ad3trim.collapsed.ad3trim.cutadapt.txt

echo "$(date +%s) Finished trimming sample $SAMPLE"

########################################################

echo "PART 4: Second collapsing"
echo "#######################################################"

echo "$(date +%s) Started second collapsing reads for sample $SAMPLE"

gunzip -c ./intermediate_files/adapter2_trim/$(basename $SAMPLE .fastq.gz).ad3trim.collapsed.ad3trim.fastq.gz | fastx_collapser -Q$QUALITY | reformat.sh qfake=40 in=stdin.fa out=$(basename $SAMPLE .fastq.gz).cleaned.fastq

echo "$(date +%s) Finished second collapsing sample $SAMPLE"

