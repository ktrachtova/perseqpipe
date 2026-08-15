#!/bin/bash
# @author: Karolina Trachtova
# @description: Script for STAR alignment of FASTQ files to genome
# @dependencies: STAR
#
set -euo pipefail

# main inputs
index=$1
input_file=$2
sample=$3
threads=$4

# STAR filtering/alignment parameters, exposed to the user; defaults match previous hardcoded values
outFilterMultimapNmax=${5:-5000}
outFilterMatchNmin=${6:-15}
outFilterMismatchNoverReadLmax=${7:-0.05}
outFilterMultimapScoreRange=${8:-0}
outFilterScoreMinOverLread=${9:-0}
outFilterMismatchNmax=${10:-999}
alignIntronMax=${11:-1}
alignIntronMin=${12:-2}

STAR --runMode alignReads \
     --runThreadN $threads \
     --genomeDir ${index} \
     --readFilesCommand zcat \
     --readFilesIn ${input_file} \
     --outFileNamePrefix ${sample}.genome. \
     --outFilterMultimapNmax $outFilterMultimapNmax \
     --outFilterMatchNmin $outFilterMatchNmin \
     --outFilterMismatchNoverReadLmax $outFilterMismatchNoverReadLmax \
     --outFilterMultimapScoreRange $outFilterMultimapScoreRange \
     --outFilterScoreMinOverLread $outFilterScoreMinOverLread \
     --outFilterMismatchNmax $outFilterMismatchNmax \
     --alignIntronMax $alignIntronMax \
     --alignIntronMin $alignIntronMin \
     --outSAMheaderHD @HD VN:1.4 SO:coordinate \
     --outSAMunmapped Within \
     --outReadsUnmapped Fastx \
     --outFilterType Normal \
     --outSAMattributes All \
     --twopassMode None \
     --outMultimapperOrder Random \
     --outSAMtype BAM SortedByCoordinate \
     --alignEndsType EndToEnd

# rename unampped fastq file and fix its header
mv ${sample}.genome.Unmapped.out.mate1 ${sample}.genome.unmapped.out.fastq
sed -i 's/0:N://g' ${sample}.genome.unmapped.out.fastq
gzip ${sample}.genome.unmapped.out.fastq
