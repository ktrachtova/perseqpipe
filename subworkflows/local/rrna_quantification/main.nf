//
// Subworkflow with functionality specific to the ktrachtova/perseqpipe pipeline
//
// This subworkflow contains code to execute rrna quantification module
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { STAR_RRNA                     } from '../../../modules/local/star_align_rrna/main'
include { ALIGNMENT_STATS               } from '../../../modules/local/alignment_stats/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO EXECUTE RRNA QUANTIFICATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow RRNA_QUANTIFICATION {

    take:
        cleaned_reads

    main:
        // Use the pre-defined STAR index path from the parameters
        // ch_rrna_index = Channel.value("${workflow.projectDir}/${params.index_rrna_path}")
        def rrna_index_path = file(params.index_rrna_path)
        if( !rrna_index_path.isAbsolute() ) {
            rrna_index_path = file("${workflow.launchDir}/${params.index_rrna_path}") 
        }
        ch_rrna_index = channel.value(rrna_index_path)

        STAR_RRNA ( ch_rrna_index , cleaned_reads)

        ALIGNMENT_STATS ( STAR_RRNA.out.rrna_aligned_bam )

    emit:
        rrna_aligned_bam         = STAR_RRNA.out.rrna_aligned_bam
        rrna_unmapped_fastq      = STAR_RRNA.out.rrna_unmapped_fastq
        rrna_logs                = STAR_RRNA.out.rrna_logs
        rrna_counts              = ALIGNMENT_STATS.out.counts
}
