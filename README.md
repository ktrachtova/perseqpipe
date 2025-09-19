<picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/logo_dark.png">
    <img alt="" src="docs/images/logo_light.png" style="margin-bottom: 20px;">
</picture>


[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)

## Introduction

**PerSeqPIPE** is a bioinformatics pipeline for analysis of small RNA-sequencing datasets focusing on sequence-centric quantification.

<picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/PerSeqPIPE.png">
    <img alt="" src="docs/images/PerSeqPIPE.png" style="margin-bottom: 20px;">
</picture>

For detailed information about individual modules, please refere to [Module description](docs/module_description.md) documentation.

## Usage

> [!NOTE]
> If you are new to Nextflow, please refer to [this page](https://www.nextflow.io/docs/latest/install.html) on how to set-up Nextflow. Make sure to test you setup with `-profile test` before running the workflow on actual data.

For instructions on how to execute the pipeline, plese refer to [Usage](docs/usage.md) documentation.

## Pipeline outputs

Outputs of PerSeqPIPE's individual modules are desribed in [Outputs](docs/outputs.md) documentation.

A full size example test run results can be downloaded here. 

## Credits

PerSeqPIPE was originally written by Karolina Trachtova.

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.