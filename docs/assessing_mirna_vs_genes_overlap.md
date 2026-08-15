# Assessing overlap between miRNA and all other genes

To access overlap between known miRNA and all other sncRNA, coding and long non-coding RNA we created script [`mirna_cross-mapping.sh`](https://github.com/ktrachtova/reference_preparation/blob/main/perseqpipe/scripts/mirna_cross-mapping.sh) which does following:

 1. Extract `gene` features for miRNA (`gene_type "miRNA"`) from GENCODE GTF file
 2. Extract all `gene`  features from custom sncRNA GTF file of PerSeqPIPE
 3. Uses `bedtools` (docker image from bioocontainers, tag `2.27.1--h077b44d_9`) to find all overlaps of at least 1bp
 4. Parses results of `bedtools` into table `mirna_sncrna_overlap_v{X.Y}.tsv` with following columns (A=miRNA genes, B=custom sncRNA GTF file genes):
    * `A_chr` chromosome of feature in database A
    * `A_start` start of feature in database A
    * `A_end` end of feature in database A
    * `A_gene_id` gene ID of feature in database A
    * `A_gene_name` gene name of feature in database A
    * `A_gene_type` gene type of feature in database A
    * `B_chr` chromosome of feature in database B
    * `B_start` start of feature in dadatabase B
    * `B_end` end of feature in database B
    * `B_gene_id` gene ID of feature in database B
    * `B_gene_name` gene name of feature in database B
    * `B_gene_type` gene type of feature in database B
    * `overlap` overlap between feature (in nucleotides) between database A and B

Before executing the script, user should downlaod a Gencode GTF file, version should correspong to the version used to create custom sncRNA GTF file as described in section [Annotation preparation](./annotation_preparation.md).

To execute the script, run following  code:
```
# unzip GTF file
gzip -d /path/to/downloaded/gencode_gtf_file.gtf.gz
GENCODE_GTF=/path/to/downloaded/gencode_gtf_file.gtf

# download custom sncRNA GTF file for PerSeqPIPE
wget https://zenodo.org/records/17700979/files/perseqpipe_all_sncrna_v1.1.gtf.gz
SNCRNA_GTF=/path/to/perseqpipe_all_sncrna_v1.1.gtf.gz

# download repository with code
git clone https://github.com/ktrachtova/reference_preparation.git

# change directory into the repo scripts/ folder
cd reference_preparation/perseqpipe/scripts

# run the script
./mirna_cross-mapping.sh $GENCODE_GTF $SNCRNA_GTF
```

The `mirna_sncrna_overlap_v{X.Y}.tsv` is generated every time a custom sncRNA GTF file is updated/changed and its version correspond to the GTF file version. This file is provided as part of PerSeqPIPE results and is located in `my_project/rna_quantification/genome/counts`. This file can be used to assess if any of the detected miRNAs do overlap sncRNAs (or _vice versa_).