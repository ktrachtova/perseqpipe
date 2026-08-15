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
include { TDRNAMER                        } from '../../../modules/local/tdrnamer/main'
include { DOWNLOAD_REFERENCES             } from '../download_references/main.nf'
include { resolveRefPath; isGenomeReferenceComplete } from '../utils_perseqpipe/main.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO EXECUTE SNCRNA QUANTIFICATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow SNCRNA_QUANTIFICATION {

    take:
        reads

    main:

        // Define correct path to reference files - genome STAR index, sncRNA GTF file and miRNA overlap file;
        // either use full path provided by user or if relative path provided, assume it is relative to launch directory
        def genome_index_path  = resolveRefPath(params.index_genome_path)
        def gtf_sncrna_path    = resolveRefPath(params.sncrna_gtf_path)
        def overlap_mirna_path = resolveRefPath(params.mirna_overlap_path)

        // Use the pre-downloaded reference files if already present, otherwise download them now
        if (isGenomeReferenceComplete(genome_index_path, gtf_sncrna_path, overlap_mirna_path)) {
            ch_genome_index  = channel.value(genome_index_path)
            ch_gtf           = channel.value(gtf_sncrna_path)
            ch_mirna_overlap = channel.value(overlap_mirna_path)
        } else {
            DOWNLOAD_REFERENCES(
                params.index_genome_url,
                params.index_genome_path,
                params.sncrna_gtf_url,
                params.sncrna_gtf_path,
                params.mirna_overlap_url,
                params.mirna_overlap_path
            )
            ch_genome_index  = DOWNLOAD_REFERENCES.out.star_index_dir
            ch_gtf           = DOWNLOAD_REFERENCES.out.gtf_file
            ch_mirna_overlap = DOWNLOAD_REFERENCES.out.mirna_path
        }

        STAR_GENOME ( ch_genome_index , reads)

        SAMTOOLS_INDEX ( STAR_GENOME.out.genome_aligned_bam )

        ALIGNMENT_STATS ( STAR_GENOME.out.genome_aligned_bam )

        ch_bam_bai = STAR_GENOME.out.genome_aligned_bam
            .join(SAMTOOLS_INDEX.out.bai)

        QUANTIFICATION_SNCRNA (
            ch_gtf,
            ch_bam_bai
        )

        TDRNAMER (
            QUANTIFICATION_SNCRNA.out.srna_counts_tsv,
            params.tdrnamer_db_url,
            params.tdrnamer_db_name,
            ch_mirna_overlap
        )

    emit:
        genome_aligned_bam         = STAR_GENOME.out.genome_aligned_bam
        genome_unmapped_fastq      = STAR_GENOME.out.genome_unmapped_fastq
        genome_logs                = STAR_GENOME.out.genome_logs
        genome_srna_counts         = QUANTIFICATION_SNCRNA.out.srna_counts_tsv
        genome_srna_counts_tdr     = TDRNAMER.out.tdr_annotated_tsv
        genome_counts              = ALIGNMENT_STATS.out.counts
}
