# PerSeqPIPE: Outputs

## Table of Contents
- [Output directory structure](#output-directory-structure)
- [Module outputs](#module-outputs)
  - [Module 1: FIRSTQC](#module-1-firstqc)
  - [Module 2: PREPROCESSING](#module-2-preprocessing)
  - [Module 3: RRNA_QUANTIFICATION](#module-3-rrna_quantification)
  - [Module 4: MIRNA_QUANTIFICATION](#module-4-mirna_quantification)
  - [Module 5: SRNA_QUANTIFICATION](#module-5-srna_quantification)
  - [Module 6: DE_ANALYSIS](#module-6-de_analysis)
- [Reads statistics](#reads-statistics)
- [sncRNA quantification output file format](#sncrna-quantification-output-file-format)
- [Pipeline information](#pipeline-information)


## Output directory structure

Below is a general directory structure of outputs when pipeline is executed with `--full-run` (running all modules of PerSeqPIPE). In case only specific modules were run (for example, DE analysis was omitted), then output folder corresponding to that module will be missing.

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

### Module 1: FIRSTQC

Results from the FIRSTQC module are stored inside `my_project/first_qc/` folder.

Folder `my_project/first_qc/fastqc` contains results of FastQC tool (.html report and .zip archive) run on raw FASTQ files.

Folder `my_project/first_qc/multiqc` contains results of MultiQC tool (main is the .html report) summarizing results of FastQC tool for all raw FASTQ files.

Folder `my_project/first_qc/stats` contains simple TXT files (`*.counts.txt`) with number of raw reads detected for each sample. These files are used to create final statistics report summarizing read numbers after individual processing steps (for more information see section **Reads statistics**).

### Module 2: PREPROCESSING

Results from the **PREPROCESSING** module are stored inside `my_project/preprocessing/` folder. 

Main outputs of **PREPROCESSING** module are:
* `{sample_id}.cleaned.fastq.gz` which are stored directly inside `my_project/preprocessing/` folder and contain final cleaned reads (after all preprocessing steps). Cleaned FASTQ files contains, regardless of undertaken preprocessing steps, collapsed reads which now have header `@seq_{Z}_x{XY}` where `XY` is number showing how many reads have that specific sequence (=were collapsed under `@seq_1_x{XY}` header). The `Z` 

Other outputs of **PREPROCESSING** module are:

* Folder `my_project/preprocessing/fastqc` contains results of FastQC tool (.html report and .zip archive) run on processed FASTQ files. After each preprocessing step (adapter trimming, collapsing etc.) FastQC tool is run to collect general statistics.

* Folder `my_project/preprocessing/intermediate_files` contains results from all but the final preprocessing step. These intermediate results might differ based on library preparation kit (for example, QIAseq uses UMIs where Truseq does not, hence results for QIAseq will contain extra steps and intermediate files). 

* Folder `my_project/preprocessing/multiqc` contains results of MultiQC tool (main is the .html report) summarizing results of FastQC tool that was run after each preprocessing step.

* Folder `my_project/preprocessing/stats` contains simple TXT files (`*.counts.txt`) with number of raw reads detected for each sample after every preprocessing step. These files are used to create final statistics report summarizing read numbers after individual processing steps (for more information see section **Reads statistics**).

### Module 3: RRNA_QUANTIFICATION

Results from the **RRNA_QUANTIFICATION** module are stored inside `my_project/rna_quantification/rrna` folder. 

Main outputs of **RRNA_QUANTIFICATION** module are:

* {sample_id}.rrna.Unmapped.out.fastq.gz files stored inside `my_project/rna_quantification/rrna/star_rrna` folder. These contains reads not aligning to rRNA reference database.

Other outputs of **RRNA_QUANTIFICATION** module are:

* All other files produced by STAR aligner, such as `*.Aligned.out.bam`, `*.Log.final.out` etc., for more information about outputs of STAR refer to its documentation.

*  Folder `my_project/rna_quantification/rrna/stats` contains simple TXT files (`*.rrna.multi.counts.txt`, `.rrna.uniq.counts.txt` and `.rrna.unmapped.counts.txt`) with number of aligned (uniquelly and multi-mapping) and unmapped reads. These files are used to create final statistics report summarizing read numbers after rRNA contamination removal (for more information see section **Reads statistics**).

> ❗ When examining results from the STAR, specifically its `.Log.final.out` files, please keep in mind that alignment statistics there are based on input FASTQ files which contains **collapsed** reads.
>
> Number of non-collapsed aligned/unmapped reads is calculated by PerSeqPIPE using information in the header of input FASTQ files and is saved inside the various `*.counts.txt` files and then summarized into final read statistics report as described in section **Reads statistics**.

### Module 4: MIRNA_QUANTIFICATION

Results from the **MIRNA_QUANTIFICATION** module are stored inside `my_project/rna_quantification/mirna` folder. 

Main outputs of **MIRNA_QUANTIFICATION** module are:

* `canonical_mirna_counts.tsv` file with raw counts for canonical miRNA

* `isomirs_counts.tsv` files with raw counts for isomiRs

* `{sample_id}.mirna.unmapped.fastq.gz` files contain miRNA-unmapped reads, which are an input for the next module

Other outputs of **MIRNA_QUANTIFICATION** module are:

* `{smaple_id}.mirna` files produced by miraligner tool are located in `my_project/rna_quantification/mirna/miraligner_mirna/`, for more information about these file please see the miraligner documentation 

*  Folder `my_project/rna_quantification/mirna/stats` contains simple TXT files (`*.mirna.mapped.counts.txt`, `.mirna.unmapped.counts.txt`) with number of mapped and unmapped reads. These files are used to create final statistics report summarizing read numbers for miRNA/isomiR quantification (for more information see section **Reads statistics**).

### Module 5: SRNA_QUANTIFICATION

Results from the **SRNA_QUANTIFICATION** module are stored inside `my_project/rna_quantification/genome` folder. 

Main outputs of **SRNA_QUANTIFICATION** module are:

* `{sample_id}.genome.short_rna_counts.tsv` files created by custom quantification script contains number of raw reads for all various sncRNAs, for more information about these files format section **sncRNA quantification output file format**. Files are stored inside folder `my_project/rna_quantification/genome/counts/`.

Other outputs of **SRNA_QUANTIFICATION** module are:

* Files produced by STAR aligner, such as `*.Aligned.out.bam`, `*.Log.final.out` etc., for more information about outputs of STAR refer to its documentation. These files are stored in folder `my_project/rna_quantification/genome/star_genome/`.

* Folder `my_project/rna_quantification/genome/stats` contains simple TXT files (`*.genome.multi.counts.txt`, `.genome.uniq.counts.txt` and `.genome.unmapped.counts.txt`) with number of aligned (uniquelly and multi-mapping) and unmapped reads. These files are used to create final statistics report summarizing read numbers after genome alignment (for more information see section **Reads statistics**).

> ❗ When examining results from the STAR, specifically its `.Log.final.out` files, please keep in mind that alignment statistics there are based on input FASTQ files which contains **collapsed** reads.
>
> Number of non-collapsed aligned/unmapped reads is calculated by PerSeqPIPE using information in the header of input FASTQ files and is saved inside the various `*.counts.txt` files and then summarized into final read statistics report as described in section **Reads statistics**.


### Module 6: DE_ANALYSIS

Outputs of DE analysis are described separately in section [Differential Expression Analysis](de_analysis.md).

## Reads statistics

A comprehensive read statistics is automatically generated at the end of PerSeqPIPE analtsis, using results from all executed modules. It contains following columns:

1. From **FIRSTQC** module
  * **raw_reads** number of reads in raw FASTA file for each sample
2. From **PREPROCESSING** module (depends on library preparation kit)
  * **adapt1_trim_reads** number of reads after initial 3' adapter trimming
  * **adapt1_trim_reads_%** percentage of reads after initial 3' adapter trimming (compared to raw reads)
  * **adapt1_short_reads** number of reads after initial 3' adapter trimming that were too short (threshold unless changed by user is 15nt)
  * **adapt1_short_reads_%** percentage of too short reads after initial 3' adapter trimming (compared to raw reads)
  * **adapt1_untrim_reads** number of reads that did not have adapter and hence were discarded
  * **adapt1_untrim_reads_%** percentage of untrimmed reads (compared to raw reads)
  * (QIAGEN-specific) **collapsed_reads** number of reads after collapsing based on UMIs
  * (QIAGEN-specific) **collapsed_reads_%** percentage of reads after collapsing based on UMIs (compared to raw reads)
  * (QIAGEN-specific) **adapt2_trim_reads** number of reads after second trimming of 3' adapter
  * (QIAGEN-specific) **adapt2_trim_reads_%** percentage of reads after second 3' adapter trimming
  * (QIAGEN-specific) **adapt2_short_reads** number of too short reads after second adapter trimming (threshold unless changed by user is 15nt)
  * (QIAGEN-specific) **adapt2_short_reads_%** percentage of too short reads after second adapter trimming
  * (QIAGEN-specific) **adapt2_untrim_reads** number of reads that did not have second 3' adapter and hence were discarded
  * (QIAGEN-specific) **adapt2_untrim_reads_%** percentage of untrimmed reads from second 3' adapter trimming
3. From **RRNA_QUANTIFICATION** module
  * **rrna_multimapped_reads** number of reads multi-mapping to rRNA database
  * **rrna_multimapped_reads_%** percentage of rRNA multi-mapping reads (compared to cleaned reads used as an input for rRNA alignment)
  * **rrna_unique_reads** number of uniquely aligned reads to rRNA database
  * **rrna_unique_reads_%** percentage of rRNA uniquely aligned reads (compared to cleaned reads used as an input for rRNA alignment)
  * **rrna_unmapped_reads** number of rRNA unmapped reads
  * **rrna_unmapped_reads_%** percentage of rRNA unmapped reads
4. From **MIRNA_QUANTIFICATION** module
  * **mirna_mapped_reads** number of reads aligning to miRNA precursors
  * **mirna_mapped_reads_%** percentage of reads aligning to miRNA precursors
  * **mirna_unmapped_reads** number of miRNA unmapped reads
  * **mirna_unmapped_reads_%** percentage of miRNA unmapped reads
5. From **GENOME_QUANTIFICATION** module
  * **genome_multimapped_reads** number of reads multi-mapping to genome
  * **genome_multimapped_reads_%** percentage of reads multi-mapping to genome
  * **genome_unique_reads** number of reads uniquely aligning to genome
  * **genome_unique_reads_%** percentage of reads uniquely aligning to genome
  * **genome_unmapped_reads** number of reads not aligning to genome
  * **genome_unmapped_reads%** percentage of reads not aligning to genome

When examining the reads statistics file, keep in mind that altough last step of preprocessing is collapsing of all cleaned sequences (to speed up subsequent quantification steps), actual  statistics always reports non-collapsed number of reads! 

File with generated statistics is in path `my_project/all_stats/read_counts_summary.csv`.

## sncRNA quantification output file format

Per-sample tab-separated files containing results from quantification of sncRNA (apart from miRNA/isomiRs) have following columns:

* **sequence** contains read sequence
* **expression** raw counts (number of a specific read)
* **pirna** list of all piRNA that overlap alignment loci of given read
* **trna** list of all tRNA that overlap alignment loci of given read
* **snorna** list of all snoRNA that overlap alignment loci of given read
* **srna** list of all other sncRNA that overlap alignment loci of given read
* **mrna** list of mRNA that overlap alignment loci of given read
* **lncrna** list of lncRNA that overlap alignment loci of given read
* **genome_alignments** number of individual genomic loci to which given read aligned to
* **MINT_plate** MINT plate for specific read

For all annotation columns, user can see none, one or multiple RNAs reported, separated by comma. Each RNA annotation value however can consist of multiple IDs, separated by "|". This means that when creating of annnotation GTF file, multiple small non-coding RNAs of the exactly the same sequence were identified across different constituend databases. For example 1 piRNA sequence present in 3 resource databases but with a different ID will be shown as `hsa-piR-1|piR-1|URS00000X`.

IDs inside annotation columns can also contain suffix `_loc{x}`. This denotes specific genomic position of annotation feature. For example, 1 piRNA is located at 2 different places inside genome. We cannot determine from which position this piRNA originated, hence both positions are reported. In practice read aligning to this specific piRNA will have `pirna` column with value `hsa-piR-1_loc1,hsa-piR-1_loc2`. It is an identical piRNA feature, but it shows there are 2 positions for it and also for the read in question. 

## Pipeline information

TO-DO: Check this section and adjust

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>