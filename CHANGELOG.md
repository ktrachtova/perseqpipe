# ktrachtova/perseqpipe: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] – 2026-01-24

### Added
- Initial public release of **perseqpipe**, a Nextflow DSL2 pipeline for sequence-oriented quantification of small non-coding RNAs from NGS data.
- End-to-end workflow covering:
  - Input validation via nf-schema and sample sheet support
  - Read preprocessing and adapter handling for multiple library types
  - rRNA filtering
  - miRNA, isomiR, and sncRNA quantification
  - Optional differential expression analysis
  - Automated QC aggregation with MultiQC
- Multiple test profiles for supported library preparation kits (e.g. QIAseq, NEXTflex, TruSeq, NEBNext, Lexogen, Norgen, Novogene).
- Docker-based execution profile for reproducible runs.
- Built-in execution reports (timeline, trace, DAG, and HTML report).
- Comprehensive user documentation included in the repository.

### Dependencies
- Requires Nextflow `>=24.04.2`.
- Primary execution environment: Docker
