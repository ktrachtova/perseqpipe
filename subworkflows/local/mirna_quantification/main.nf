include { MIRALIGNER_MIRNA } from '../../../modules/local/miraligner_mirna/main'
include { ISOMIRS_STATS    } from '../../../modules/local/isomirs_stats/main'

workflow MIRNA_QUANTIFICATION {

    take:
        cleaned_reads

    main:
        ch_miraligner_db = Channel.fromPath(params.miraligner_db).collect()

        MIRALIGNER_MIRNA(ch_miraligner_db, cleaned_reads)
        // fastqc_mirna(mirna_alignment.out.mirna_unmapped_fastq, 'rna_quantification/mirna/qc')

        // multiqc_mirna(fastqc_mirna.out.fastqc_results.collect(), 'rna_quantification/mirna/qc')

        ch_mirna_files = Channel.empty()
        ch_mirna_files = MIRALIGNER_MIRNA.out.mirna_aligned
            .map { it[1] } // Extract the file path from the tuple
            .collect() // Collect all items into a single list
        ISOMIRS_STATS(ch_mirna_files.collect())

        //multiqc_mirna(
        //
        //    fastqc_mirna.out.fastqc_html
        //        .mix(fastqc_mirna.out.fastqc_zip.flatten())
        //        .collect(), 'rna_quantification/mirna/qc'
        //)
    emit:
        mirna_mapped_files          = MIRALIGNER_MIRNA.out.mirna_aligned
        mirna_unmapped_files        = MIRALIGNER_MIRNA.out.mirna_unmapped_fastq
        mirna_counts                = MIRALIGNER_MIRNA.out.mirna_counts

        mirna_canonical_tsv         = ISOMIRS_STATS.out.canonical_mirna_table
        mirna_isomirs_tsv           = ISOMIRS_STATS.out.isomirs_table

        //mirna_fastqc_html         = fastqc_mirna.out.fastqc_html
        //mirna_fastqc_zip          = fastqc_mirna.out.fastqc_zip
        //mirna_fastqc_statistics   = fastqc_mirna.out.fastqc_statistics
}