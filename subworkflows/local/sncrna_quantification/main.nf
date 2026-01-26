//
// Subworkflow with functionality specific to the ktrachtova/perseqpipe pipeline
//
// This subworkflow contains code to execute sncrna quantification module
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { STAR_GENOME                     } from '../../../modules/local/star_align_genome/main'
include { SAMTOOLS_INDEX                  } from '../../../modules/nf-core/samtools/index/main'                                                   
include { ALIGNMENT_STATS                 } from '../../../modules/local/alignment_stats/main'
include { QUANTIFICATION_SNCRNA           } from '../../../modules/local/quantification_sncrna/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO EXECUTE SNCRNA QUANTIFICATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow SNCRNA_QUANTIFICATION {

    take:
        reads

    main:

        // ch_genome_index = Channel.value("${workflow.projectDir}/${params.index_genome_path}")

        // Define correct path to reference files - genome STAR index, sncRNA GTF file and miRNA overlap file;
        // either use full path provided by user or if relative path provided, assume it is relative to launch directory
        def genome_index_path = file(params.index_genome_path)
        if( !genome_index_path.isAbsolute() ) {
            genome_index_path = file("${workflow.launchDir}/${params.index_genome_path}") 
        }
        ch_genome_index = channel.value(genome_index_path)

        def gtf_sncrna_path = file(params.sncrna_gtf_path)
        if( !gtf_sncrna_path.isAbsolute() ) {
            gtf_sncrna_path = file("${workflow.launchDir}/${params.sncrna_gtf_path}") 
        }
        ch_gtf = channel.value(gtf_sncrna_path)

        def overlap_mirna_path = file(params.mirna_overlap_path)
        if( !overlap_mirna_path.isAbsolute() ) {
            overlap_mirna_path = file("${workflow.launchDir}/${params.mirna_overlap_path}") 
        }
        ch_mirna_overlap = channel.value(overlap_mirna_path)

        STAR_GENOME ( ch_genome_index , reads)

        SAMTOOLS_INDEX ( STAR_GENOME.out.genome_aligned_bam )

        ALIGNMENT_STATS ( STAR_GENOME.out.genome_aligned_bam )

        ch_bam_bai = STAR_GENOME.out.genome_aligned_bam
            .join(SAMTOOLS_INDEX.out.bai)

        // ch_gtf = Channel.value("${workflow.projectDir}/${params.sncrna_gtf_path}")
        // ch_mirna_overlap = Channel.value("${workflow.projectDir}/${params.mirna_overlap_path}")

        QUANTIFICATION_SNCRNA (
            ch_gtf,
            ch_mirna_overlap,
            ch_bam_bai
        )


    emit:
        genome_aligned_bam         = STAR_GENOME.out.genome_aligned_bam
        genome_unmapped_fastq      = STAR_GENOME.out.genome_unmapped_fastq
        genome_logs                = STAR_GENOME.out.genome_logs
        genome_srna_counts         = QUANTIFICATION_SNCRNA.out.srna_counts_tsv
        genome_counts              = ALIGNMENT_STATS.out.counts
}
