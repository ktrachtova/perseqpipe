/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'

include { FIRSTQC                } from '../subworkflows/local/first_qc/main.nf'
include { PREPROCESSING          } from '../subworkflows/local/preprocessing/main.nf'
include { RRNA_QUANTIFICATION    } from '../subworkflows/local/rrna_quantification/main.nf'
include { MIRNA_QUANTIFICATION   } from '../subworkflows/local/mirna_quantification/main.nf'
include { SNCRNA_QUANTIFICATION  } from '../subworkflows/local/sncrna_quantification/main.nf'
include { DE_ANALYSIS            } from '../subworkflows/local/de_analysis/main.nf'

include { CALCULATE_ALL_STATS    } from '../modules/local/calculate_all_stats/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// ─── Expand implicit dependencies ──────────────────────────────────────
def do_firstqc          = params.run_firstqc
def do_preprocessing    = params.run_preprocessing
def do_rrna             = params.run_rrna
def do_mirna            = params.run_mirna
def do_sncrna           = params.run_sncrna
def do_full             = params.run_full


if (do_preprocessing) {
    do_firstqc = true
}

if (do_rrna) {
    do_firstqc = true
    do_preprocessing = true
}

if (do_mirna) {
    do_firstqc = true
    do_preprocessing = true
    do_rrna = true
}

if (do_sncrna) {
    do_firstqc = true
    do_preprocessing = true
    do_rrna = true
    do_mirna = true
}

if (do_full) {
    do_firstqc = true
    do_preprocessing = true
    do_rrna = true
    do_mirna = true
    do_sncrna = true
}

workflow PERSEQPIPE {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    if (do_firstqc) {
        FIRSTQC (
            ch_samplesheet
        )
    }

    if (do_preprocessing) {
        PREPROCESSING (
            ch_samplesheet
        )
    }

    if (do_rrna) {
        RRNA_QUANTIFICATION (
            PREPROCESSING.out.cleaned_reads
        )
    }

    if (do_mirna) {
        MIRNA_QUANTIFICATION (
            RRNA_QUANTIFICATION.out.rrna_unmapped_fastq
        )
    }
    
    if (do_sncrna) {
        SNCRNA_QUANTIFICATION (
            MIRNA_QUANTIFICATION.out.mirna_unmapped_files,
        )
    }

    if (do_full) {
        DE_ANALYSIS (
            MIRNA_QUANTIFICATION.out.mirna_canonical_tsv,
            MIRNA_QUANTIFICATION.out.mirna_isomirs_tsv,
            SNCRNA_QUANTIFICATION.out.genome_srna_counts.collect({it[1]})
        )
    }

    if (do_sncrna || do_full) {

        ch_counts_files = 
            FIRSTQC.out.fastqc_counts.collect({it[1]})
            .mix(PREPROCESSING.out.preprocessed_counts.collect({it[1]}))
            .mix(RRNA_QUANTIFICATION.out.rrna_counts.collect({it[1]}))
            .mix(MIRNA_QUANTIFICATION.out.mirna_counts.collect({it[1]}))
            .mix(SNCRNA_QUANTIFICATION.out.genome_counts.collect({it[1]})).flatten().collect()

        CALCULATE_ALL_STATS (
            ch_counts_files
        )
    }

    emit:
    multiqc_report = FIRSTQC.out.multiqc_report // channel: /path/to/multiqc_report.html
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
