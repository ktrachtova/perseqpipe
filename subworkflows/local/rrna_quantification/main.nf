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
include { DOWNLOAD_REFERENCES           } from '../download_references/main.nf'
include { resolveRefPath; isStarIndexComplete } from '../utils_perseqpipe/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO EXECUTE RRNA QUANTIFICATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow RRNA_QUANTIFICATION {

    take:
        cleaned_reads

    main:
        // Use the pre-downloaded STAR index if already present, otherwise download it now
        def rrna_index_path = resolveRefPath(params.index_rrna_path)

        if (isStarIndexComplete(rrna_index_path)) {
            ch_rrna_index = channel.value(rrna_index_path)
        } else {
            DOWNLOAD_REFERENCES(params.index_rrna_url, params.index_rrna_path, '', '', '', '')
            ch_rrna_index = DOWNLOAD_REFERENCES.out.star_index_dir
        }

        STAR_RRNA ( ch_rrna_index , cleaned_reads)

        ALIGNMENT_STATS ( STAR_RRNA.out.rrna_aligned_bam )

    emit:
        rrna_aligned_bam         = STAR_RRNA.out.rrna_aligned_bam
        rrna_unmapped_fastq      = STAR_RRNA.out.rrna_unmapped_fastq
        rrna_logs                = STAR_RRNA.out.rrna_logs
        rrna_counts              = ALIGNMENT_STATS.out.counts
}
