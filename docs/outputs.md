# PerSeqPIPE: Outputs

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



## Reads statistics

TO-DO: Describe the file with read statistics and its individual fields

## sncRNA quantification output file format

TO-DO: Desribe what is inside out custom TSV files from quantification




## Introduction

This document describes the output produced by the PerSeqPIPE pipeline. Most of the plots are taken from the MultiQC report, which summarises results at the end of the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

<!-- TODO nf-core: Write this documentation describing your workflow's output -->

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [FastQC](#fastqc) - Raw read QC
- [MultiQC](#multiqc) - Aggregate report describing results and QC from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### FastQC

<details markdown="1">
<summary>Output files</summary>

- `fastqc/`
  - `*_fastqc.html`: FastQC report containing quality metrics.
  - `*_fastqc.zip`: Zip archive containing the FastQC report, tab-delimited data file and plot images.

</details>

[FastQC](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/) gives general quality metrics about your sequenced reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences. For further reading and documentation see the [FastQC help pages](http://www.bioinformatics.babraham.ac.uk/projects/fastqc/Help/).

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc/`
  - `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.
  - `multiqc_data/`: directory containing parsed statistics from the different tools used in the pipeline.
  - `multiqc_plots/`: directory containing static images from the report in various formats.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Most of the pipeline QC results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline QC from supported tools e.g. FastQC. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
