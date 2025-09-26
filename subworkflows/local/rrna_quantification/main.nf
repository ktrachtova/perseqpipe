include { STAR_RRNA                     } from '../../../modules/local/star_align_rrna/main'
include { STAR_GENOMEGENERATE           } from '../../../modules/local/star_genomegenerate/main'
include { ALIGNMENT_STATS               } from '../../../modules/local/alignment_stats/main'

workflow RRNA_QUANTIFICATION {

    take:
        cleaned_reads

    main:
        // Use the pre-defined STAR index path from the parameters
        ch_rrna_index = Channel.value("${workflow.projectDir}/${params.index_rrna_path}")
        STAR_RRNA ( ch_rrna_index , cleaned_reads)

        ALIGNMENT_STATS ( STAR_RRNA.out.rrna_aligned_bam )

    emit:
        rrna_aligned_bam         = STAR_RRNA.out.rrna_aligned_bam
        rrna_unmapped_fastq      = STAR_RRNA.out.rrna_unmapped_fastq
        rrna_logs                = STAR_RRNA.out.rrna_logs
        rrna_counts              = ALIGNMENT_STATS.out.counts

        //rrna_quantification_fastqc_html         = fastqc_rrna.out.fastqc_html
        //rrna_quantification_fastqc_zip          = fastqc_rrna.out.fastqc_zip
        //rrna_quantification_fastqc_statistics   = fastqc_rrna.out.fastqc_statistics
}
