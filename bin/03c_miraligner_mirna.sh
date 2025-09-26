#!/bin/bash
#
# Perform miRNA alignment to miRBase using miraligner tool
# The main focus is to get good alignment without to much bias
# For quantification, it's necessary to run the postprocessing R script! 
#
# http://seqcluster.readthedocs.io/mirna_annotation.html#mirna-isomir-annotation-with-java
# http://seqcluster.readthedocs.io/mirna_annotation.html#manual-of-miraligner-java
#
# Requires: seqcluster, miraligner, crossmap.py from miraligner (optional), R, isomiRs (https://github.com/lpantano/isomiRs)
#
# TODO Merge contamination removal with the mapping script to keep miRNA reads which map with 0 mismatch but with 1 mismatch to contaminants
#
################################################################################################################
set -euo pipefail

miraligner_db=$1
input_file=$2
sample=$3           # sample name
miraligner_path=$4

mismatch=1 # [0, 1] Allows only 0 or 1 mismatch
add=3 # Max. number of additions (non-templated)
trim=3 # Max. number of trimmings

echo "Processing $input_file"
unpigz -c $input_file > ${input_file%.gz}
java -jar ${miraligner_path} -freq -sub $mismatch -trim $trim -add $add -minl 16 -s hsa -i ./${input_file%.gz} -db $miraligner_db -o ./${sample} # -pre: add sequences mapping to precur>

cut -f2 ./${sample}.mirna | sort | uniq  > mapped.names
sed -i 's/^/@/' mapped.names
awk 'NR % 4 == 1' ${input_file%.gz} > all.names
grep -v -w -F -f mapped.names all.names > nomap.names
grep --no-group-separator -A 3 -w -F -f nomap.names ${input_file%.gz} > ${sample}.mirna.unmapped.fastq
sed -i 's/ //g' ${sample}.mirna.unmapped.fastq
pigz ${sample}.mirna.unmapped.fastq
rm mapped.names all.names nomap.names

sed '1d' ./${sample}.mirna | cut -f2 | cut -d'x' -f2 | awk '{s+=$1} END {print s}' > ./${sample}.mirna.mapped.counts.txt
zgrep '@seq' ${sample}.mirna.unmapped.fastq.gz | cut -d'x' -f2 | awk '{s+=$1} END {print s}' > ${sample}.mirna.unmapped.counts.txt

#done