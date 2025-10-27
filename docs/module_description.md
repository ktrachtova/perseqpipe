# PerSeqPIPE: Module description

The PerSeqPIPE consists of **6 main modules** (which correspond to subworkflows in Nextflow syntax):  
1. FirstQC (FIRSTQC)  
2. Preprocessing (PREPROCESSING)  
3. rRNA quantification / contamination removal (RRNA_QUANTIFICATION)  
4. miRNA / isomiR quantification (MIRNA_QUANTIFICATION)  
5. Other sncRNA quantification (SNCRNA_QUANTIFICATION)  
6. DE analysis (DE_ANALYSIS)  

## Module 1️⃣: FirstQC  

The FIRSTQC module checks the quality of raw sequencing data. It uses `FastQC` to scan each sample for various quality metrics and `MultiQC` to aggregate all per-sample results from `FastQC` into one HTML report.  

## Module 2️⃣: Preprocessing  

The PREPROCESSING module cleans raw sequencing reads and prepares FASTQ files with collapsed reads for subsequent alignment. Based on the library preparation kit specified by the user through the parameter `--lib_type`, the following set of preprocessing steps will be executed:  

1. Remove adapters from the 3’ end (`cutadapt`)  
2. (Optional: QIAseq) Collapse reads using UMIs (`fastx_collapser`, `bbmap`)  
3. (Optional: QIAseq) Remove second 3’ end adapters and UMIs (`cutadapt`)  
4. (Optional: Nextflex V3) Remove the first 4 and last 4 bases from each read (`cutadapt`)  
5. Collapse cleaned reads (`fastx_collapser`, `bbmap`)  

The output of the PREPROCESSING module consists of cleaned, collapsed reads ready for alignment (suffix `.cleaned.reads.fastq.gz`). The new header of each collapsed read sequence contains a unique sequence ID, followed by the number of reads that have the same sequence (example: `seq_{XY}_x10` where `XY` is unique sequence ID and `x10` means there were 10 reads with identical sequence). When calculating [read statistics](outputs.md#reads-statistics), the read count for each unique sequence is added together to provide with real read count.

Each type of preprocessed read also undergoes post-processing checks with `FastQC`, and an overall `MultiQC` HTML report is produced, summarizing the quality of all samples after each preprocessing step.  

Currently supported library preparation kits:  
* QIAseq miRNA Library Kit (QIAGEN)  
* TruSeq Small RNA Library Preparation Kit  
* NEBNext Small RNA Library Prep Set for Illumina  
* NEXTFLEX Small RNA-Seq Kit V3  
* NEXTFLEX Small RNA-Seq Kit V4  
* CleanTag Small RNA Library Preparation Kit (TriLink)  
* Small RNA-Seq Library Prep Kit (Lexogen)  
* Small RNA Sequencing Novogene  

## Module 3️⃣: rRNA quantification  

Cleaned reads from preprocessing are aligned to a custom set of rRNA sequences (see [Annotation preparation](annotation_preparation.md)) using `STAR`, with parameters adjusted for the alignment of short reads that can originate from several hundred similar rRNA sequences.

## Module 4️⃣: miRNA/isomiR quantification  

Reads unmapped to rRNA are aligned to miRNA precursor sequences using the `miraligner` tool (by default miRBase v22; alternatively, v21 can be chosen using the parameter `--mirbase_version`). The R package `isomiRs` is then used to produce raw counts for both canonical miRNAs and isomiRs.  

## Module 5️⃣: Other sncRNA quantification  

Reads not aligning to miRNA are aligned to the human genome (GRCh38) using `STAR`, with several parameters adjusted for short-read alignment. BAM files from alignment and our GTF file for all sncRNA classes are used as input for a custom in-house Python quantification script (which uses `HTSeq` Python library). This script counts all reads, including multimapping ones, and creates a table where, for each read sequence, a list of all possible annotations is provided.   

Users can change thresholds such as the minimum number of identical reads required for a sequence to be reported (`--reads_threshold`), or the minimum length of overlap between a read and an annotation feature for it to be assigned (`--sncrna_overlap` and `--sncrna_overlap_frac`).  If user sets these parameteres to `null`, default values will be always used (`reads_threshold=1` and `sncrna_overlap=5`). If both `--sncrna_overlap` and `--sncrna_overlap_frac` specified, the stricter of the two will be used. 

Distinct sncRNA classes currently quantified:  
* tRNA  
* piRNA  
* snoRNA  
* sncRNA_other (snRNA, scaRNA, scRNA, sRNA, misc_RNA)  

Other RNA classes included in the reference, and therefore also quantified if fragments originate from them:  
* mRNA  
* lncRNA  

## Module 6️⃣: Differential expression analysis  

Currently, there are two modes for running the DE analysis module (DE_ANALYSIS). If the user does not provide a design file (option `--design`), only raw and normalized counts (`edgeR` TMM, VST, and `DESeq2` normalized) will be produced. If a design file is provided, full DE analysis using `DESeq2` will be performed.  

The DE_ANALYSIS module is run once for miRNAs/isomiRs (counts obtained through the **MIRNA_QUANTIFICATION** module) and once for all other RNA classes (counts obtained through the **SNCRNA_QUANTIFICATION** module).  

For more information about the statistical analysis, please refer to the dedicated section on [DE analysis](de_analysis.md).  