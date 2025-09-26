# PerSeqPIPE: Usage

> [!NOTE]
> If you are new to Nextflow, please refer to [this](https://nf-co.re/docs/usage/installation) page on how to set-up Nextflow. Make sure to run a test (see section Running tests) first before processing actual data.

## General execution and pipeline versioning

To run the PerSeqPIPE, you can download and execute it with one command:
```
nextflow run ktrachtova/perseqpipe -r v1.0.0 ...
```

This will automatically download pipeline code of specific version and execute the pipeline. 

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [PerSeqPIPE releases page](https://github.com/ktrachtova/perseqpipe/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

## Step 1: Download reference

In order to run rRNA and sncRNA quantification modules, user must first download STAR index for rRNA database and human genome and a custom sncRNA GTF file (see [Reference databases](reference_databases.md) for a list of resources). This can be easily done by running following two commands:

```
nextflow run main.nf --download_reference_rrna

nextflow run main.nf --download_reference_genome
```

This will download and unzip STAR index folder into the folder `resources/star_rrna` and `resources/star_genome` respectively. The sncRNA GTF file will be also downloaded and placed into `resources/` folder. Both indexes and the GTF file will be automatically picked by PerSeqPIPE when executed on real datasets. Optionally, if user wishes to use own STAR index it is possible to use parameters `--index_genome_url` and `--index_genome_path` to change location and name of used index (identical parameters exist also for the rRNA index and GTF file).

> [!WARNING]
> Downloading both STAR indexes will take some time, compressed index for human genome is ~9GB. 

## Step 2: Running PerSeqPIPE

### Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location.

```bash
--input_samplesheet '[path to samplesheet file]'
```

Samplesheet has to be a comma-separated file with 2 columns, and a header row as shown in the examples below.

```
sample,fastq_1
SRR11631009_plasma_1,/path/to/SRR11631009_plasma_1.fastq.gz
SRR11631010_plasma_2,/path/to/SRR11631010_plasma_2.fastq.gz
```

The specified path can either be local or point to accessible external storage. 

### PerSeqPIPE module execution

To run a full PerSeqPIPE workflow (assuming you already downlaoded all reference files required and these are now located in `resources/` folder), following command can be used:

```
nextflow run main.nf ktrachtova/perseqpipe -r v1.0.0 -profile [docker,conda] --input_samplesheet /path/to/input/samplesheet --outdir /path/to/project/outputs --design_file /path/to/design --run_full 
```

As mentioned in section [Module description](module_description.md), PerSeqPIPE consists of 6 modules that can be executed separately. Which module is executed can be controlled with following parameters:


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
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

## Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull ktrachtova/perseqpipe
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/srnaseq releases page](https://github.com/nf-core/srnaseq/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Two genetics profiles (Docker, Conda) are currently bundled with the pipeline which instruct the pipeline how to use software packages .

> [!IMPORTANT]
> We highly recommend the use of Docker containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.

Note that multiple profiles can be loaded, for example: `-profile docker,arm` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

Currently available profiles (excluding test-related profiles, for these see section Running tests)

- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker.
- `arm`
  - A generic configuration profile to be used when running pipeline on ARM architecture


### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).