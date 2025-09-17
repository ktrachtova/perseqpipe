# PerSeqPIPE: Reference databases for sncRNA annotation

To quantify all different sncRNAs currently known we have prepared an annotation GTF file for sncRNAs by combining information from multiple publicly available resources. This GTF file is automatically downloaded by PerSeqPIPE and used by the **GENOME_QUANTIFICATION** module. In case you want to reproduce or update certain resources from which the annotation GTF file was built, please see section Annotation preparation.

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




