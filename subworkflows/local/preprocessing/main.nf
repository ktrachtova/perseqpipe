//
// Subworkflow with functionality specific to the ktrachtova/perseqpipe pipeline
//
// This subworkflow contains code to execute preprocessing module
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                  } from '../../../modules/local/fastqc/main'
include { MULTIQC                 } from '../../../modules/nf-core/multiqc/main'
include { PREPROCESSING_RAW_READS } from '../../../modules/local/preprocessing_raw_reads/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO EXECUTE PREPROCESSING
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow PREPROCESSING {
    take:
        reads
    main:
        PREPROCESSING_RAW_READS ( reads )

        ch_intermediates_files = PREPROCESSING_RAW_READS.out.intermediates
                                    .mix(PREPROCESSING_RAW_READS.out.intermediates_discarded)
                                    .transpose()

        FASTQC (ch_intermediates_files )

        ch_multiqc_config        = Channel.fromPath(
            "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
        ch_multiqc_custom_config = params.multiqc_config ?
            Channel.fromPath(params.multiqc_config, checkIfExists: true) :
            Channel.empty()
        ch_multiqc_logo          = params.multiqc_logo ?
            Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
            Channel.empty()

        ch_multiqc_files = Channel.empty()
        ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})

        MULTIQC (
            ch_multiqc_files,
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList(),
            [],
            []
        )
        
    emit:
        cleaned_reads           = PREPROCESSING_RAW_READS.out.cleaned_reads
        intermediates           = PREPROCESSING_RAW_READS.out.intermediates
        intermediates_discarded = PREPROCESSING_RAW_READS.out.intermediates_discarded
        len_dist                = PREPROCESSING_RAW_READS.out.len_distributions
        preprocessed_counts     = FASTQC.out.fastqc_counts

}