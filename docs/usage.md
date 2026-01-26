# PerSeqPIPE: Usage

## Table of Contents
- [General execution](#general-execution)
- [Download reference](#download-reference)
- [Running PerSeqPIPE](#running-perseqpipe)
  - [Samplesheet input](#samplesheet-input)
  - [PerSeqPIPE module execution](#perseqpipe-module-execution)
  - [Parameters](#parameters)
- [Updating the pipeline](#updating-the-pipeline)
- [Reproducibility](#reproducibility)
- [Core Nextflow arguments](#core-nextflow-arguments)
- [Custom configuration](#custom-configuration)
  - [Resource requests](#resource-requests)
- [Running in the background](#running-in-the-background)
- [Running tests](#running-tests)

## General execution

> [!NOTE]
> If you are new to Nextflow, please refer to [this](https://nf-co.re/docs/usage/installation) page on how to set-up Nextflow. Make sure to run a test (see section [Running tests](#running-tests)) first before processing actual data.

To run PerSeqPIPE on real data, it is first required to [download reference files](#download-reference), such as the STAR index, mialigner database, and GTF file for sncRNA quantification. This step is performed separately from the actual analysis and needs to be completed only once per computational environment.

To run PerSeqPIPE (both for downloading reference files and analysis of actual data), first download the repository locally and navigate to the `perseqpipe/` directory. Then run PerSeqPIPE using the following command:

```
git clone https://github.com/ktrachtova/perseqpipe.git
cd perseqpipe
nextflow run main.nf <OTHER_PARAMETERS>
```

Alternatively, Nextflow can automatically download the pipeline code when executed using the following syntax:

```
nextflow run ktrachtova/perseqpipe <OTHER_PARAMETERS>
```

When using this command, Nextflow will:
1. Download the PerSeqPIPE pipeline code from GitHub and cache it locally.
2. Execute the pipeline from the cached copy.
3. Create a `work/` directory and a `.nextflow.log` file in the directory where the command was launched.

The pipeline source code itself is not copied into the current directory.

For the exact commands and all required parameters, refer to the sections [Download reference](#download-reference) and [Running PerSeqPIPE](#running-perseqpipe).

## Download reference

In order to run rRNA and sncRNA quantification modules, user must first download STAR index for rRNA database and human genome and a custom sncRNA GTF file (see [Reference databases](reference_databases.md) for a list of resources). This can be easily done by running following two commands:

```
nextflow run main.nf --download_reference_rrna

nextflow run main.nf --download_reference_genome
```

This will download and unzip STAR index folder into the folder `./resources/star_rrna` and `./resources/star_genome` respectively. The sncRNA GTF file will be also downloaded and placed into `./resources/` folder. Both indexes and the GTF file will be automatically picked by PerSeqPIPE when executed on real datasets. Optionally, if user wishes to use own STAR index it is possible to use parameters `--index_genome_url` and `--index_genome_path` to change location and name of used index (identical parameters exist also for the rRNA index and GTF file).

> [!WARNING]
> Downloading STAR index for whole genome will take some time (based on download speed) as the compressed index has size of ~9GB.

> [!IMPORTANT]
> The reference files are always downloaded into the `resources/` folder within the launch directory. When analyzing real data, PerSeqPIPE expects to find the `resources/` folder in the directory from which it is launched (unless specified otherwise via the `--index_genome_path` or `--index_rrna_path` parameters). If the pipeline is launched from a different directory than the one containing the `resources/` folder and the reference path is not specified correctly, it will terminate with an error.

> [!NOTE]
> Altough no `-profile` option is required for downloading reference, an automatic warning will be shown that the pipeline was executed without any custom configuration. This warning can be ignored.

## Running PerSeqPIPE

### Samplesheet input

Prior to running PerSeqPIPE, user needs to create a samplesheet with information about the samples that will be analyzed. Following parameter is used to specify its location when executing PerSeqPIPE.

```bash
--input_samplesheet <SAMPLESHEET>
```

Samplesheet has to be a comma-separated file with 2 columns, and a header row as shown in the examples below.

```
sample,fastq_1
SRR11631009_plasma_1,/path/to/SRR11631009_plasma_1.fastq.gz
SRR11631010_plasma_2,/path/to/SRR11631010_plasma_2.fastq.gz
```

The specified path can either be local or point to accessible external storage. 

### PerSeqPIPE module execution

To run a full PerSeqPIPE workflow (assuming you already downlaoded all reference files required and these are now located in `./resources/` folder), following command can be used:

```
nextflow run main.nf \
  -profile <docker> \
  --input_samplesheet <SAMPLESHEET> \
  --outdir <OUTDIR> \
  --design_file <DESIGN_FILE> \
  --lib_type <LIB_TYPE> \
  --run_full 
```

For list of available library types `<LIB_TYPE>`, see [Parameters](parameters.md#preprocessing-options).

As mentioned in section [Module description](module_description.md), PerSeqPIPE consists of six sequential modules. The selected module determines the **final module in the execution chain**, and all preceding modules are executed automatically. Which module is executed can be controlled using the following parameters:


| parameter             | decription                              |
|-----------------------|-----------------------------------------|
| `--run_firstqc`       | Run FIRSTQC module only                 |
| `--run_preprocessing` | Run modules up to PREPROCESSING         |
| `--run_rrna`          | Run modules up to RRNA_QUANTIFICATION   |
| `--run_mirna`         | Run modules up to MIRNA_QUANTIFICATION  |
| `--run_sncrna`        | Run modules up to SNCRNA_QUANTIFICATION |
| `--run_full`          | Run all modules                         |

Execution of the pipeline will create following pipeline-related files in the working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow.log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

### Parameters

For a complete list of parameters, please see section [Parameters](parameters.md).

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

A generic Docker profile is currently bundled with the pipeline which instruct the pipeline how to use software packages .

Note that multiple profiles can be loaded, for example: `-profile docker,arm` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

Currently available profiles (excluding test-related profiles, for these see section Running tests)

- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `arm`
  - A generic configuration profile to be used when running pipeline on ARM architecture


### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time, which are specified through config file `base.config` or optionally, through `local.config`. 

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Running tests

To test the workflow, user can select from several small test profiles, one for each library preparation kit.

| profile name | library preparation kit |
| -------------|-------------------------|
| test_qiaseq  | QIAseq miRNA Library Kit (QIAGEN) |
| test_truseq  | TruSeq Small RNA Library Preparation Kit |
| test_nebnext | NEBNext Small RNA Library Prep Set for Illumina |
| test_nextflexV3 | NEXTFLEX Small RNA-Seq Kit V3 |
| test_nextflexV4 | NEXTFLEX Small RNA-Seq Kit V4 |
| test_trilink | CleanTag Small RNA Library Preparation Kit (TriLink) |
| test_lexogen | Small RNA-Seq Library Prep Kit (Lexogen) |
| test_novogene | Small RNA Sequencing Novogene |
| test_norgen | Norgen Small RNA Library Prep Kit |

To execute a specific minimal test, run following command (here shown example to run QIAseq-specific test):
```
nextflow run main.nf -profile <docker>,test_qiaseq --outdir <OUTDIR>
```