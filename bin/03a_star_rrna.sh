#!/bin/bash
# @author: Karolina Trachtova
# @description: Script for STAR alignment of cleaned FASTQ files to rRNA sequences
# @dependencies: STAR
#
set -euo pipefail

index=$1            # STAR rRNA index
input_file=$2       # input .fastq.gz file
sample=$3           # sample name
threads=$4          # threads for STAR
outFilterMultimapNmax=${5:-5000}
outFilterMatchNmin=${6:-15}
outFilterMismatchNoverReadLmax=${7:-0.05}
outFilterMultimapScoreRange=${8:-0}
outFilterScoreMinOverLread=${9:-0}
outFilterMismatchNmax=${10:-999}
alignIntronMax=${11:-1}
alignIntronMin=${12:-2}
seedSearchStartLmax=${13:-10}
winAnchorMultimapNmax=${14:-1000}

STAR --runMode alignReads \
     --runThreadN $threads \
     --genomeDir $index \
     --readFilesCommand zcat \
     --readFilesIn $input_file \
     --outFileNamePrefix ${sample}.rrna. \
     --outFilterMultimapNmax $outFilterMultimapNmax \
     --outFilterMatchNmin $outFilterMatchNmin \
     --outFilterMismatchNoverReadLmax $outFilterMismatchNoverReadLmax \
     --outFilterMultimapScoreRange $outFilterMultimapScoreRange \
     --outFilterScoreMinOverLread $outFilterScoreMinOverLread \
     --outFilterMismatchNmax $outFilterMismatchNmax \
     --alignIntronMax $alignIntronMax --alignIntronMin $alignIntronMin \
     --outSAMheaderHD @HD VN:1.4 SO:coordinate \
     --outSAMunmapped Within \
     --outReadsUnmapped Fastx \
     --outFilterType Normal \
     --outSAMattributes All \
     --twopassMode None \
     --seedSearchStartLmax $seedSearchStartLmax \
     --winAnchorMultimapNmax $winAnchorMultimapNmax \
     --outMultimapperOrder Random \
     --outSAMtype BAM Unsorted \
     --alignEndsType EndToEnd

# rename unampped fastq file and fix its header
mv ${sample}.rrna.Unmapped.out.mate1 ${sample}.rrna.Unmapped.out.fastq
sed -i 's/ .*//g' ${sample}.rrna.Unmapped.out.fastq
gzip ${sample}.rrna.Unmapped.out.fastq
