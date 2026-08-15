# PerSeqPIPE: Module description

## Table of Contents
- [Overview](#perseqpipe-module-description)
- [Module 1️⃣: FirstQC](#module-1️⃣-firstqc)
- [Module 2️⃣: Preprocessing](#module-2️⃣-preprocessing)
- [Module 3️⃣: rRNA quantification](#module-3️⃣-rrna-quantification)
- [Module 4️⃣: miRNA/isomiR quantification](#module-4️⃣-mirnaisomir-quantification)
- [Module 5️⃣: Other sncRNA quantification](#module-5️⃣-other-sncrna-quantification)
- [Module 6️⃣: Differential expression analysis](#module-6️⃣-differential-expression-analysis)

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

The output of the PREPROCESSING module consists of cleaned, collapsed reads ready for alignment (suffix `.cleaned.reads.fastq.gz`). The new header of each collapsed read sequence contains a unique sequence ID, followed by the number of reads that have the same sequence (example: `seq_{XY}_x10` where `XY` is unique sequence ID and `x10` means there were 10 reads with identical sequence). When calculating read statistics, the read count for each unique sequence is added together to provide with real read count. For more information about read statistics, see section **Reads statistics** in [Outputs](outputs.md#reads-statistics).

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

After sncRNA quantification, the counts table is further annotated by the **TDR_NAMING** process using [tDRnamer](https://github.com/UCSC-LoweLab/tDRnamer). Each read sequence is matched against the tDRnamer reference database (currently `hg38`) to assign a standardized tRNA-derived RNA (tDR) name, following the naming system proposed by the tRNA research community (Holmes et al. 2023). The resulting `tdr_name` is added as an extra column to the sncRNA counts table; sequences not recognized as tDRs by tDRnamer are left blank.

### Quantification of miRNA/isomiR VS other sncRNA

miRNAs are among the best-studied classes of small non-coding RNAs. Their biogenesis is well characterized, and the mechanisms generating isomiRs—sequence variants arising from trimming, extension, or nucleotide modifications—are relatively well understood, even though their exact biological functions are still being uncovered. Historically, miRNA expression analyses aggregated all isomiRs belonging to a canonical miRNA, regardless of sequence differences. As the importance of isomiRs became clearer, specialized tools and a dedicated naming system were developed to detect, classify, and report these variants with high specificity.

Other classes of sncRNAs, however, are far less studied and lack comparable tools, nomenclature, or standardized annotation practices. Because of this disparity, the quantification of other sncRNA classes requires a different approach than the quantification of miRNAs and isomiRs.

When developing PerSeqPIPE, we chose to keep miRNA/isomiR quantification separate from all other sncRNAs for these reasons. To further justify this design, we generated a table summarizing overlap between miRNA genes and all other genes (coding, long non-coding and small non-coding), using the custom sncRNA GTF file used within the SNCRNA_QUANTIFCATION module. The table (available at OSF [here](https://osf.io/zne7g/overview)) shows that miRNA loci overlap only minimally with other sncRNA classes—specifically, 74 piRNA genes, 18 snoRNA genes, and 1 tRNA gene—while most overlaps occur with protein-coding or lncRNA genes. This supports treating miRNA/isomiR quantification as a separate step, since potential ambiguity with other sncRNAs is limited.

For users who wish to investigate possible cross-origin signals—e.g., whether sequences quantified as sncRNAs in their dataset might originate from miRNA loci, or vice versa—we provide this static overlap table as a part of PerSeqPIPE results. Detailed steps for generating the overlap file are described in [**Assessing overlap between miRNA and all other genes**](assessing_mirna_vs_genes_overlap.md).

## Module 6️⃣: Differential expression analysis  

Currently, there are two modes for running the DE analysis module (DE_ANALYSIS). If the user does not provide a design file (option `--design`), only raw and normalized counts (`edgeR` TMM, VST, and `DESeq2` normalized) will be produced. If a design file is provided, full DE analysis using `DESeq2` will be performed.  

The DE_ANALYSIS module is run once for miRNAs/isomiRs (counts obtained through the **MIRNA_QUANTIFICATION** module) and once for all other RNA classes (counts obtained through the **SNCRNA_QUANTIFICATION** module).  

For more information about the statistical analysis, please refer to the dedicated section on [DE analysis](de_analysis.md).  