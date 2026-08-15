# PerSeqPIPE: Outputs

## Table of Contents
- [Output directory structure](#output-directory-structure)
- [Module outputs](#module-outputs)
  - [Module 1️⃣: FIRSTQC](#module-1️⃣-firstqc)
  - [Module 2️⃣: PREPROCESSING](#module-2️⃣-preprocessing)
  - [Module 3️⃣: RRNA_QUANTIFICATION](#module-3️⃣-rrna_quantification)
  - [Module 4️⃣: MIRNA_QUANTIFICATION](#module-4️⃣-mirna_quantification)
  - [Module 5️⃣: SNCRNA_QUANTIFICATION](#module-5️⃣-sncrna_quantification)
  - [Module 6️⃣: DE_ANALYSIS](#module-6️⃣-de_analysis)
- [Reads statistics](#reads-statistics)
- [sncRNA quantification output file format](#sncrna-quantification-output-file-format)


## Output directory structure

Below is a general directory structure of outputs when pipeline is executed with parameter `--full-run` (running all modules of PerSeqPIPE). In case only specific modules were run (for example, DE analysis was omitted), then output folder corresponding to that module will be missing.

```
my_project/
  all_stats/
  first_qc/
      fastqc/
      multiqc/
      stats/
  preprocessing/
      fastqc/
      intermediate_files/
      multiqc/
      stats/
      *.cleaned.fastq.gz
  rna_quantification/
      genome/
          counts/
          star_genome/
          stats/
      mirna/
          miraligner/
          stats/
      rrna/
          star_rrna/
          stats/
  de_analysis/
      mirna_isomirs/
      srna/
  pipeline_info/
```

## Module outputs

This section describes output files created by individual modules.

### Module 1️⃣: FIRSTQC

Results from the FIRSTQC module are stored inside `my_project/first_qc/` folder.

Folder `my_project/first_qc/fastqc` contains results of the FastQC tool (.html report and .zip archive) run on raw FASTQ files.

Folder `my_project/first_qc/multiqc` contains results of MultiQC tool (main is the .html report) summarizing results of the FastQC tool for all raw FASTQ files.

Folder `my_project/first_qc/stats` contains simple TXT files (`*.counts.txt`) with number of raw reads detected for each sample. These files are used to create final statistics report summarizing read numbers after individual processing steps (for more information see section [Reads statistics](#reads-statistics)).

### Module 2️⃣: PREPROCESSING

Results from the **PREPROCESSING** module are stored inside `my_project/preprocessing/` folder. 

Main outputs of **PREPROCESSING** module are:
* `{sample_id}.cleaned.fastq.gz` which are stored directly inside `my_project/preprocessing/` folder and contain final cleaned reads (after all preprocessing steps). Cleaned FASTQ with collapsed reads have a header in the format `@seq_{Z}_x{XY}` where `XY` depicts how many reads have that specific sequence (were collapsed under `@seq_1_x{XY}` header). `Z` is a random unique number.

Other outputs of **PREPROCESSING** module are:

* Folder `my_project/preprocessing/fastqc` contains results of the FastQC tool (.html report and .zip archive) executed on processed FASTQ files. After each preprocessing step (adapter trimming, collapsing etc., depends on library preparation kit) FastQC tool is run to collect general statistics.

* Folder `my_project/preprocessing/intermediate_files` contains results from all but the final preprocessing step. These intermediate results might differ based on library preparation kit (for example, QIAseq uses UMIs where Truseq does not, hence results for QIAseq will contain extra steps and intermediate files). 

* Folder `my_project/preprocessing/multiqc` contains results of MultiQC tool (main is the .html report) summarizing results of the FastQC tool that was run after each preprocessing step.

* Folder `my_project/preprocessing/stats` contains simple TXT files (`*.counts.txt`) with number of raw reads detected for each sample after every preprocessing step. These files are used to create final statistics report summarizing read numbers after individual processing steps (for more information see section [Reads statistics](#reads-statistics)).

### Module 3️⃣: RRNA_QUANTIFICATION

Results from the **RRNA_QUANTIFICATION** module are stored inside `my_project/rna_quantification/rrna` folder. 

Main outputs of **RRNA_QUANTIFICATION** module are:

* `{sample_id}.rrna.Unmapped.out.fastq.gz` files stored inside `my_project/rna_quantification/rrna/star_rrna` folder. These contain reads not aligning to the rRNA reference database.

Other outputs of **RRNA_QUANTIFICATION** module are:

* All other files produced by STAR aligner, such as `*.Aligned.out.bam`, `*.Log.final.out` etc., for more information about outputs of STAR refer to its documentation.

*  Folder `my_project/rna_quantification/rrna/stats` contains simple TXT files (`*.rrna.multi.counts.txt`, `.rrna.uniq.counts.txt` and `.rrna.unmapped.counts.txt`) with number of aligned (uniquely and multi-mapping) and unmapped reads. These files are used to create final statistics report summarizing read numbers after rRNA contamination removal (for more information see section [Reads statistics](#reads-statistics)).

> [!IMPORTANT] When examining results from the STAR, specifically its `.Log.final.out` files, please keep in mind that alignment statistics there are based on input FASTQ files which contain **collapsed** reads.
>
> Number of non-collapsed aligned/unmapped reads is calculated by PerSeqPIPE using information in the header of input FASTQ files and is saved inside the various `*.counts.txt` files and then summarized into final read statistics report as described in section [Reads statistics](#reads-statistics).

### Module 4️⃣: MIRNA_QUANTIFICATION

Results from the **MIRNA_QUANTIFICATION** module are stored inside `my_project/rna_quantification/mirna` folder. 

Main outputs of **MIRNA_QUANTIFICATION** module are:

* `canonical_mirna_counts.tsv` file with raw counts for canonical miRNA

* `isomirs_counts.tsv` files with raw counts for isomiRs

* `{sample_id}.mirna.unmapped.fastq.gz` files contain miRNA-unmapped reads, which are the input for the next module

Other outputs of **MIRNA_QUANTIFICATION** module are:

* `{smaple_id}.mirna` files produced by miraligner tool are located in `my_project/rna_quantification/mirna/miraligner_mirna/`, for more information about these files, please see the miraligner documentation 

*  Folder `my_project/rna_quantification/mirna/stats` contains simple TXT files (`*.mirna.mapped.counts.txt`, `.mirna.unmapped.counts.txt`) with number of mapped and unmapped reads. These files are used to create final statistics report summarizing read numbers for miRNA/isomiR quantification (for more information see section [Reads statistics](#reads-statistics)).

### Module 5️⃣: SNCRNA_QUANTIFICATION

Results from the **SNCRNA_QUANTIFICATION** module are stored inside `my_project/rna_quantification/genome` folder. 

Main outputs of **SNCRNA_QUANTIFICATION** module are:

* `{sample_id}.genome.short_rna_counts.tsv` files created by a custom quantification script and further annotated with tDR names by the **TDRNAMER** process (using [tDRnamer](https://github.com/UCSC-LoweLab/tDRnamer)) contain the number of raw reads for all various sncRNAs, for more information about these files see section [**sncRNA quantification output file format**](#sncrna-quantification-output-file-format). Files are stored inside folder `my_project/rna_quantification/genome/counts/`.


Other outputs of **SNCRNA_QUANTIFICATION** module are:

* Files produced by STAR aligner, such as `*.Aligned.out.bam`, `*.Log.final.out` etc., for more information about outputs of STAR refer to its documentation. These files are stored in folder `my_project/rna_quantification/genome/star_genome/`.

* Folder `my_project/rna_quantification/genome/stats` contains simple TXT files (`*.genome.multi.counts.txt`, `.genome.uniq.counts.txt` and `.genome.unmapped.counts.txt`) with number of aligned (uniquely and multi-mapping) and unmapped reads. These files are used to create final statistics report summarizing read numbers after genome alignment (for more information see section **Reads statistics**).

> [!IMPORTANT]
> When examining results from the STAR, specifically its `.Log.final.out` files, please keep in mind that alignment statistics there are based on input FASTQ files which contain **collapsed** reads.
>
> Number of non-collapsed aligned/unmapped reads is calculated by PerSeqPIPE using information in the header of input FASTQ files and is saved inside the various `*.counts.txt` files and then summarized into final read statistics report as described in section [Reads statistics](#reads-statistics).


### Module 6️⃣: DE_ANALYSIS

Outputs of DE analysis are described separately in section [Differential Expression Analysis](de_analysis.md).

## Reads statistics

A comprehensive read statistics is automatically generated at the end of PerSeqPIPE analysis, using results from all executed modules. It contains the following columns:

1. From **FIRSTQC** module
  * `raw_reads` is number of reads in the raw FASTA file for each sample
2. From **PREPROCESSING** module (depends on library preparation kit)
  * `adapt1_trim_reads` is number of reads after initial 3' adapter trimming
  * `adapt1_trim_reads_%` is percentage of reads after initial 3' adapter trimming (compared to raw reads)
  * `adapt1_short_reads` is number of reads after initial 3' adapter trimming that were too short (threshold unless changed by user is 15nt)
  * `adapt1_short_reads_%` is percentage of too short reads after initial 3' adapter trimming (compared to raw reads)
  * `adapt1_untrim_reads` is number of reads that did not have adapter and hence were discarded
  * `adapt1_untrim_reads_%` is percentage of untrimmed reads (compared to raw reads)
  * (QIAGEN-specific) `collapsed_reads` is number of reads after collapsing based on UMIs
  * (QIAGEN-specific) `collapsed_reads_%` is percentage of reads after collapsing based on UMIs (compared to raw reads)
  * (QIAGEN-specific) `adapt2_trim_reads` is number of reads after second trimming of 3' adapter
  * (QIAGEN-specific) `adapt2_trim_reads_%` is percentage of reads after second 3' adapter trimming
  * (QIAGEN-specific) `adapt2_short_reads` is number of too short reads after second adapter trimming (threshold unless changed by user is 15nt)
  * (QIAGEN-specific) `adapt2_short_reads_%` is percentage of too short reads after second adapter trimming
  * (QIAGEN-specific) `adapt2_untrim_reads` is number of reads that did not have second 3' adapter and hence were discarded
  * (QIAGEN-specific) `adapt2_untrim_reads_%` is percentage of untrimmed reads from second 3' adapter trimming
3. From **RRNA_QUANTIFICATION** module
  * `rrna_multimapped_reads` is number of reads multi-mapping to rRNA database
  * `rrna_multimapped_reads_%` is percentage of rRNA multi-mapping reads (compared to cleaned reads used as an input for rRNA alignment)
  * `rrna_unique_reads` is number of uniquely aligned reads to rRNA database
  * `rrna_unique_reads_%` is percentage of rRNA uniquely aligned reads (compared to cleaned reads used as an input for rRNA alignment)
  * `rrna_unmapped_reads` is number of rRNA unmapped reads
  * `rrna_unmapped_reads_%` is percentage of rRNA unmapped reads
4. From **MIRNA_QUANTIFICATION** module
  * `mirna_mapped_reads` is number of reads aligning to miRNA precursors
  * `mirna_mapped_reads_%` is percentage of reads aligning to miRNA precursors
  * `mirna_unmapped_reads` is number of miRNA unmapped reads
  * `mirna_unmapped_reads_%` is percentage of miRNA unmapped reads
5. From **GENOME_QUANTIFICATION** module
  * `genome_multimapped_reads` is number of reads multi-mapping to genome
  * `genome_multimapped_reads_%` is percentage of reads multi-mapping to genome
  * `genome_unique_reads` is number of reads uniquely aligning to genome
  * `genome_unique_reads_%` is percentage of reads uniquely aligning to genome
  * `genome_unmapped_reads` is number of reads not aligning to genome
  * `genome_unmapped_reads%` is percentage of reads not aligning to genome

When examining the reads statistics file, keep in mind that although last step of preprocessing is collapsing of all cleaned sequences (to speed up subsequent quantification steps), actual statistics always report the non-collapsed number of reads! 

File with generated statistics is in path `my_project/all_stats/read_counts_summary.csv`.

## sncRNA quantification output file format

Per-sample tab-separated files with suffix `.short_rna_counts.tsv` contain results from quantification of sncRNA (apart from miRNA/isomiRs) and have the following columns:

* `sequence` contains read sequence
* `expression` raw counts (number of a specific read)
* `pirna` list of all piRNA that overlap alignment loci of given read
* `trna` list of all tRNA that overlap alignment loci of given read
* `snorna` list of all snoRNA that overlap alignment loci of given read
* `srna` list of all other sncRNA that overlap alignment loci of given read
* `mrna` list of mRNA that overlap alignment loci of given read
* `lncrna` list of lncRNA that overlap alignment loci of given read
* `genome_alignments` number of individual genomic loci to which given read aligned to
* `MINT_plate` contains sequence-specific and unique identifier (license-plate), more information [here](https://github.com/TJU-CMC-Org/MINTplates)
* `tdr_name` contains the standardized tRNA-derived RNA (tDR) name assigned by [tDRnamer](https://github.com/UCSC-LoweLab/tDRnamer); blank if the sequence was not recognized as a tDR


For all annotation columns, the user can see none, one or multiple RNAs reported, separated by comma. Each RNA annotation can contain multiple sncRNA IDs, separated by `|` (pipe). This means that when creating the annotation GTF file, multiple sncRNAs with identical sequence were identified across different databases. For example, 1 piRNA sequence present in 3 databases (each has its own naming system) will be shown as `hsa-piR-1|piR-1|URS00000X`.

IDs inside annotation columns can also contain suffix `_loc{x}`. This denotes specific genomic position of annotation feature. For example, 1 piRNA is located at 2 different places inside the genome. We cannot determine from which position this piRNA originated, hence both positions are reported. In practice read aligning to this specific piRNA will have `pirna` column with value `hsa-piR-1_loc1,hsa-piR-1_loc2`. It is an identical piRNA feature, but it shows that it can originate from 2 distinct genomic loci.docs/outputs.md
