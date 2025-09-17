#!/bin/bash
# Script for STAR alignment of cleaned FASTQ files to rRNA sequences
# @author: Karolina Trachtova
# @script: 03a_star_rrna.sh

index=$1            # STAR rRNA index
input_file=$2       # input .fastq.gz file
sample=$3           # sample name
threads=$4          # threads for STAR

STAR --runMode alignReads \
     --runThreadN $threads \
     --genomeDir $index \
     --readFilesCommand zcat \
     --readFilesIn $input_file \
     --outFileNamePrefix ${sample}.rrna. \
     --outFilterMultimapNmax 5000 \
     --outFilterMatchNmin 15 \
     --outFilterMismatchNoverReadLmax 0.05 \
     --outFilterMultimapScoreRange 0 \
     --outFilterScoreMinOverLread 0 \
     --outFilterMismatchNmax 999 \
     --alignIntronMax 1 --alignIntronMin 2 \
     --outSAMheaderHD @HD VN:1.4 SO:coordinate \
     --outSAMunmapped Within \
     --outReadsUnmapped Fastx \
     --outFilterType Normal \
     --outSAMattributes All \
     --twopassMode None \
     --seedSearchStartLmax 10 \
     --winAnchorMultimapNmax 1000 \
     --outMultimapperOrder Random \
     --outSAMtype BAM Unsorted \
     --alignEndsType EndToEnd

# rename unampped fastq file and fix its header
mv ${sample}.rrna.Unmapped.out.mate1 ${sample}.rrna.Unmapped.out.fastq
sed -i 's/ .*//g' ${sample}.rrna.Unmapped.out.fastq
gzip ${sample}.rrna.Unmapped.out.fastq

# get number of counts -> take from BAM file based on read names that contain real number of reads before pre-alignment collapsing
# rrna unmapped
#samtools view ${input_file%.fastq.gz}.rrna.Aligned.out.bam | grep -w "NH:i:0" | cut -f1 | cut -d'x' -f2 | awk '{s+=$1} END {print s}' > ${input_file%.fastq.gz}.rrna.unmapped.counts.txt
# rrna uniq
#samtools view ${input_file%.fastq.gz}.rrna.Aligned.out.bam | grep -w "NH:i:1" | cut -f1 | cut -d'x' -f2 | awk '{s+=$1} END {print s}' > ${input_file%.fastq.gz}.rrna.uniq.counts.txt
# rrna multi
#samtools view ${input_file%.fastq.gz}.rrna.Aligned.out.bam | grep -v -w "NH:i:1" | grep -v -w "NH:i:0" | cut -f1 | sort | uniq | cut -d'x' -f2 | awk '{s+=$1} END {print s}' > ${input_file%.fastq.gz}.rrna.multi.counts.txt