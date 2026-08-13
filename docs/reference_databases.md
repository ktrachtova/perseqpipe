# PerSeqPIPE: Reference databases for sncRNA annotation

To quantify all different sncRNAs currently known we have prepared an [annotation GTF file](https://zenodo.org/records/17700979) for sncRNAs by combining information from multiple publicly available resources. This GTF file is automatically downloaded by PerSeqPIPE and used by the **SNCRNA_QUANTIFICATION** module. In case you want to reproduce or update certain resources from which the annotation GTF file was built, please see section [Annotation preparation](./annotation_preparation.md).

Below we provide information about resources for each sncRNA class and how many sequences were extracted.

## rRNA

rRNA sequences were collected from two resources - NCBI and RNACentral (v24). 

For RNACentral, rRNA sequences were searched for using pattern: `((rRNA* AND TAXONOMY:"9606" AND so_rna_type_name:"RRNA") AND entry_type:"Sequence")`. 

rRNA sequences downloaded from NCBI were searched with terms 'Homo Sapiens' and 'rRNA'.

Overall number of sequences after removing redundant sequences: **9,171**

## tRNA

tRNA sequences were collected from two resources - GtRNAdb (data release 22, Sept 2024) and GENCODE (v47). From GtRNAdb, high confidence set, notable atypical predictions as well all other tRNA-like predictions were used. From Gencode 22 mitochondrial tRNA sequences were extracted (class `Mt_tRNA`).  

Overall number of sequences after removing redundant sequences: **641**

## piRNA

piRNA sequences were collected from 4 different resources - piRNAdb (v1.7.6), piRBase (v3.0), RNACentral (v24) and NCBI.

piRNA sequences from RNACentral database were obtained using search pattern `((piRNA* AND so_rna_type_name:"PiRNA" AND TAXONOMY:"9606") AND entry_type:"Sequence")` .

For NCBI, searched terms were 'Homo Sapiens' and 'piRNA'.

Overall number of sequences after removing redundant sequences: **109,834**

## snoRNA

snoRNA sequences were extracted from 2 resources - RNACentral (v24) and Gencode (v47).

snoRNA sequences from RNACentral database were obtained using search pattern `((snoRNA* AND so_rna_type_name:"SnoRNA" AND TAXONOMY:"9606") AND entry_type:"Sequence")` . 

Overall number of sequences after removing redundant sequences: **2,657**

## miRNA

For miRNA quantification, miRBase (v22) is used as a primary source of miRNA sequences. 


## Other sncRNA

This group comprises various RNAs that do not fit any other category. Contains following gene types from Gencode:
* `snRNA`
* `scRNA`
* `sRNA`
* `misc_RNA`

Coordinates for these RNAs were extracted directly from GENCODE (v47).

## mRNA / lncRNA

Both mRNA and lncRNA sequences are also considered during quantification as recent research acknowledges a possibility of various mRNA and lncRNA fragments presence in small RNA-sequencing data. 

mRNA and lncRNA coordinates were extracted from Gencode (v47). 


## miRNA MirGeneDB database

From release `2.0.0` PerSeqPIPE supports both miRBase and MirGeneDB for miRNA/isomiR quantification. 

To prepare a MirGeneDB database in a format accepted by `miraligner` tool, 2 files (genomic coordinates in BED and a precursor w/flank 30nt FASTA file) are required. These can be downloaded directly from [MirGeneDB](https://mirgenedb.org/download). For reproducibility purposes, we also store these two files used to create a database for current PerSeqPIPE release ([hsa-all.bed](https://osf.io/zne7g/files/hacuk), [hsa-pri.fas](https://osf.io/zne7g/files/b5e6t)). These correspond to MirGeneDB 3.0 version. 

Below are instruction on how to create a MirGeneDB for `miraligner`. The used scripts was adapted from code of https://github.com/miRTop/mirtop.

```
# download hsa-all.bed and hsa-pri.fas from MirGeneDB or use commands below
wget -O hsa-all.bed https://osf.io/hacuk/download
wget -O hsa-pri.fas https://osf.io/b5e6t/download

# script create_mirgenedb_db.py is located in perseqpipe/scripts;
python3 create_mirgenedb_db.py \
  --bed hsa-all.bed --fasta hsa-pri.fas --species hsa --outdir mirgene
mv hsa.hairpin.fa hairpin.fa
mv hsa.miRNA.str miRNA.str
```

The `create_mirgenedb_db.py` creates two files needed by `miraligner` - hairpin.fa and miRNA.str. These two files are stored in a folder available here, and are supplied to PerSeqPIPE through paramater `miraligner_db_url`.

