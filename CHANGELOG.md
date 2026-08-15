# ktrachtova/perseqpipe: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] – 2026-08-15

### Added

* Added Apptainer support as an alternative to Docker for reproducible pipeline execution.
* Added [MirGeneDB](https://mirgenedb.org/) as an alternative miRNA annotation resource.
* Added tRNA-derived fragment naming using tDRnamer.
* Added automatic download and preparation of required reference resources when starting the pipeline.
* Added additional documentation describing pipeline configuration, computational resource requirements, reference preparation, and execution options.

### Changed

* Updated pipeline parameters, including parameter renaming that introduces a breaking change from version 1.x.
  - parameter `miraligner_db_url` contianing path to miRBase reference was changed to `mirbase_db`
* Expanded support for execution on local systems and HPC environments using Docker or Apptainer.
* Updated reference preparation and annotation workflows to accommodate the newly supported resources.
* Updated pipeline documentation and usage instructions throughout the repository.

### Dependencies

* Requires Nextflow `>=24.04.2`.
  - Please note that in Nextflow 26.04 and higher, strict syntax parser is the default; the PerSeqPIPE right now does not work correctly with the strict syntax parser, hence, if Nextflow 26.04 or higher is being used variable `NXF_SYNTAX_PARSER` has to be set to `v1` prior to running the PerSeqPIPE; this will be fixed in the next release
* Supported container runtimes: Docker and Apptainer.

## [1.0.0] – 2026-01-27

### Added

* Initial public release of **perseqpipe**, a Nextflow DSL2 pipeline for sequence-oriented quantification of small non-coding RNAs from NGS data.
* End-to-end workflow covering:

  * Input validation via nf-schema and sample sheet support
  * Read preprocessing and adapter handling for multiple library types
  * rRNA filtering
  * miRNA, isomiR, and sncRNA quantification
  * Optional differential expression analysis
  * Automated QC aggregation with MultiQC
* Multiple test profiles for supported library preparation kits (e.g. QIAseq, NEXTflex, TruSeq, NEBNext, Lexogen, Norgen, Novogene).
* Docker-based execution profile for reproducible runs.
* Built-in execution reports (timeline, trace, DAG, and HTML report).
* Comprehensive user documentation included in the repository.

### Dependencies

* Requires Nextflow `>=24.04.2`.
* Primary execution environment: Docker.
