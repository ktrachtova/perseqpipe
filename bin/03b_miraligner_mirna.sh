#!/bin/bash
# @author: Karolina Trachtova
# @description: Perform miRNA alignment to miRBase using miraligner tool
# @dependencies: mirliagner
#
set -euo pipefail

# main inputs
miraligner_db=$1
input_file=$2
sample=$3
miraligner_path=$4
species=$5

mismatch=1  # [0, 1] Allows only 0 or 1 mismatch
add=3       # Max. number of additions (non-templated)
trim=3      # Max. number of trimmings

# running miraligner
echo "Processing $input_file"
unpigz -c $input_file > ${input_file%.gz}
java -jar ${miraligner_path} -freq -sub $mismatch -trim $trim -add $add -minl 16 -s $species -i ./${input_file%.gz} -db $miraligner_db -o ./${sample}

# extract mirna-aligner reads into FASTQ files
cut -f2 ./${sample}.mirna | sort | uniq  > mapped.names
sed -i 's/^/@/' mapped.names
awk 'NR % 4 == 1' ${input_file%.gz} > all.names

# extract unmapped reads into FASTQ files
grep -v -w -F -f mapped.names all.names > nomap.names
grep --no-group-separator -A 3 -w -F -f nomap.names ${input_file%.gz} > ${sample}.mirna.unmapped.fastq
sed -i 's/ //g' ${sample}.mirna.unmapped.fastq
pigz ${sample}.mirna.unmapped.fastq
rm mapped.names all.names nomap.names

# create files with counts of both mapped and unmapped reads for overall statistics
sed '1d' ./${sample}.mirna | cut -f2 | cut -d'x' -f2 | awk '{s+=$1} END {print s}' > ./${sample}.mirna.mapped.counts.txt
zgrep '@seq' ${sample}.mirna.unmapped.fastq.gz | cut -d'x' -f2 | awk '{s+=$1} END {print s}' > ${sample}.mirna.unmapped.counts.txt
