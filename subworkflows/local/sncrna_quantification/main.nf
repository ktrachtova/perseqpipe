include { STAR_GENOME                     } from '../../../modules/local/star_align_genome/main'
include { STAR_GENOMEGENERATE             } from '../../../modules/local/star_genomegenerate/main'
include { SAMTOOLS_INDEX                  } from '../../../modules/nf-core/samtools/index/main'                                                   
include { ALIGNMENT_STATS                 } from '../../../modules/local/alignment_stats/main'
include { QUANTIFICATION_SNCRNA           } from '../../../modules/local/quantification_sncrna/main'

workflow SNCRNA_QUANTIFICATION {

    take:
        reads

    main:

        ch_genome_index = Channel.value("${workflow.projectDir}/${params.index_genome_path}")

        STAR_GENOME ( ch_genome_index , reads)

        SAMTOOLS_INDEX ( STAR_GENOME.out.genome_aligned_bam )

        ALIGNMENT_STATS ( STAR_GENOME.out.genome_aligned_bam )

        // ch_sncrna_gtf = params.sncrna_gtf

        ch_bam_bai = STAR_GENOME.out.genome_aligned_bam
            .join(SAMTOOLS_INDEX.out.bai)

        ch_gtf = Channel.value("${workflow.projectDir}/${params.sncrna_gtf_path}")

        QUANTIFICATION_SNCRNA (
            ch_gtf,
            ch_bam_bai
        )


    emit:
        genome_aligned_bam         = STAR_GENOME.out.genome_aligned_bam
        genome_unmapped_fastq      = STAR_GENOME.out.genome_unmapped_fastq
        genome_logs                = STAR_GENOME.out.genome_logs
        genome_srna_counts         = QUANTIFICATION_SNCRNA.out.srna_counts_tsv
        genome_counts              = ALIGNMENT_STATS.out.counts
}
