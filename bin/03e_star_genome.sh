#!/bin/bash
set -euo pipefail

# main inputs
index=$1
input_file=$2
sample=$3

#gunzip -f $input_file
#sed -i 's/ //g' ${input_file%.gz}

STAR --runMode alignReads \
     --genomeDir ${index} \
     --readFilesCommand zcat \
     --readFilesIn ${input_file} \
     --outFileNamePrefix ${sample}.genome. \
     --outFilterMultimapNmax 5000 \
     --outFilterMatchNmin 15 \
     --outFilterMismatchNoverReadLmax 0.05 \
     --outFilterMultimapScoreRange 0 \
     --outFilterScoreMinOverLread 0 \
     --outFilterMismatchNmax 999 \
     --alignIntronMax 1 \
     --alignIntronMin 2 \
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
