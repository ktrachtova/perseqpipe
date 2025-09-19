# PerSeqPIPE: Module description

The PerSeqPIPE consists of 6 main modules:
1. FirstQC
2. Preprocessing
3. rRNA quantification (contamination removal)
4. miRNA/isomiR quantification
5. Other sncRNA quantification
6. DE analysis

## Module 1: FirstQC

The FIRSTQC module checks the quality of raw sequencing data. It uses FastQC to scan each samples for various quality metrics and MultiQC to aggregate all results from FastQC into one HTML report. 

## Module 2: Preprocessing

The PREPROCESSING module cleans raw sequencing reads and prepares FASTQ files with collapsed reads for subsequent alignment. Based on library preparation kit that user specifies through parameter `--lib_type`, following set of preprocessing steps will be executed:

1. Remove adapters from 3’ end (cutadapt)
2. (Optional: QIAseq) Collapsing reads using UMIs (fastx_collapser, bbmap)
3. (Optional: QIAseq) Removing second 3’ end adapters and UMIs (cutadapt)
4. (Optional: Nextflex V3) Removing first 4 and last 4 bases from each reads (cutadapt)
5. Collapsing cleaned reads (fastx_collapser, bbmap)

Output of the PREPROCESSING module are cleaned collapsed reads ready for alignment (suffix `.cleaned.reads.fastq.gz`). Each type of preprocessed reads also undergoes post-processing checks with FastQC and an overall MultiQC HTML report is produced summarizing the quality of all samples after each preprocessing step.

Currently supported library preparation kits:
* QIAseq miRNA Library Kit (QIAGEN)
* TruSeq Small RNA Library Preparation Kit
* NEBNext Small RNA Library Prep Set for Illumina
* NEXTFLEX Small RNA-Seq Kit V3
* NEXTFLEX Small RNA-Seq Kit V4
* CleanTag Small RNA Library Preparation Kit (TriLink)
* Small RNA-Seq Library Prep Kit (Lexogen)
* Small RNA Sequencing Novogene

## Module 3: rRNA quantification
Cleaned reads from preprocessing are aligned to a custom set of rRNA sequences (see chapter [Annotation preparation](annotation_preparation.md)) using STAR with parameters adjusted for alignment of short reads that can originate from several hundred similar rRNA sequences.

## Module 4: miRNA/isomiR quantification

rRNA unmapped reads are aligned to miRNA precursor sequences using miraligner tool (by default miRBase v22, but using parameter `-–mirbase_version` user can choose also v21). R package `isomiRs` is then used to produce raw counts for both canonical miRNA and isomiRs. 

## Module 5: Other sncRNA quantification

Reads not aligning to miRNA are aligned to the human genome GRCh38 using STAR. Several parameters of STAR are adjusted for alignment of short reads. BAM files from alignment and our GTF file for all sncRNAs classes are used as an input for custom in-house Python quantification script. Our quantification script counts all, even multimapping reads and creates a table where for each read sequence a list of all possible annotations is provided.

User can change thresholds such as minimal number of identical reads for a read sequence to be reported or length of overlap between a read and annotation feature for an annotation to be assigned to a specific read sequence. 

Distinct sncRNA classes currently quantified:
* tRNA
* piRNA
* snoRNA
* sncRNA_other (snRNA, scaRNA, scRNA, sRNA, misc_RNA)

Other RNA classes that are also part of a reference and hence fragments originating from them are also quantified:
* mRNA
* lncRNA

## Module 4: Differential expression analysis

Currently, there are 2 modes for running the DE analysis module (DE_ANALYSIS). If user does not provide a design file (option `--design`), then only raw and normalized counts (edgeR TMM, VST, and DESeq2 normalized) will be produced. If a user provides a design file, full DE analysis using DESeq2 will be performed.

Differential expression analysis module (**DE_ANALYSIS**) is run once for miRNA/isomiRs (counts obtained through **MIRNA_QUANTIFICATION** module) and once for all other RNA classes (counts obtained through **GENOME_QUANTIFICATION** module).

For more information about the statistical analysis please refer to specical section on [DE analysis](de_analysis.md).