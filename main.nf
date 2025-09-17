#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/srnaseq
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github :        https://github.com/ktrachtova/perseqpipe
    Documentation : !FILLIN!
    Email :         k.trachtova@gmail.com
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PERSEQPIPE  }                from './workflows/perseqpipe'
include { DOWNLOAD_REFERENCES }       from './subworkflows/local/download_references/main.nf'
include { PIPELINE_INITIALISATION }   from './subworkflows/local/utils_nfcore_srnaseq_pipeline'
include { PIPELINE_COMPLETION     }   from './subworkflows/local/utils_nfcore_srnaseq_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    DOWNLOAD REFERENCES WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow PERSEQPIPE_WF {

    take:
    samplesheet // channel: samplesheet read in from --input

    main:

    //
    // WORKFLOW: Run pipeline
    //
    PERSEQPIPE (
        samplesheet
    )
    emit:
    multiqc_report = PERSEQPIPE.out.multiqc_report // channel: /path/to/multiqc_report.html
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:
    //
    // SUBWORKFLOW: Run initialisation tasks
    //
    PIPELINE_INITIALISATION (
        params.version,
        params.validate_params,
        params.monochrome_logs,
        args,
        params.outdir,
        params.input_samplesheet
    )

    //
    // WORKFLOW: Run main workflow - either download reference or actually analyze some samples
    //

    if (params.download_reference_rrna || params.download_reference_genome) {
        
            // Create empty channels for optional outputs
        Channel
            .empty()
            .set { ch_star_rrna_index }

        Channel
            .empty()
            .set { ch_star_genome_index }

            // Conditionally run rRNA index download
        if (params.download_reference_rrna) {
            ch_star_rrna_index = DOWNLOAD_REFERENCES(
                params.index_rrna_url,
                params.index_rrna_name,
                'resources/star_rrna'
            ).out.star_index_dir
        }

        if (params.download_reference_genome) {
            ch_star_genome_index = DOWNLOAD_REFERENCES(
                params.index_genome_url,
                params.index_genome_name,
                'resources/star_genome'
            ).out.star_index_dir
        }

    } else {
        PERSEQPIPE_WF (
            PIPELINE_INITIALISATION.out.samplesheet
        )

        PIPELINE_COMPLETION (
            params.email,
            params.email_on_fail,
            params.plaintext_email,
            params.outdir,
            params.monochrome_logs,
            params.hook_url,
            PERSEQPIPE_WF.out.multiqc_report
        )
    }
    //
    // SUBWORKFLOW: Run completion tasks
    //

    // !FILLIN!

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
