//
// Subworkflow with functionality specific to the ktrachtova/perseqpipe pipeline
//
// This subworkflow contains code to execute mirna/isomirs quantification module
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { MIRALIGNER_MIRNA } from '../../../modules/local/miraligner_mirna/main'
include { ISOMIRS_STATS    } from '../../../modules/local/isomirs_stats/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO EXECUTE MIRNA/ISOMIRS QUANTIFICATION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow MIRNA_QUANTIFICATION {

    take:
        cleaned_reads

    main:
        // select DB and miraligner species flag based on the requested miRNA pipeline
        if (params.miraligner_db == 'mirgenedb') {
            mirna_db      = params.mirgenedb_db
            mirna_species = 'Hsa'
        } else if (params.miraligner_db == 'mirbase') {
            mirna_db      = params.mirbase_db
            mirna_species = 'hsa'
        } else {
            error "Invalid value for params.miraligner_db: '${params.miraligner_db}'. Must be one of ['mirbase', 'mirgenedb']."
        }

        MIRALIGNER_MIRNA(mirna_db, mirna_species, cleaned_reads)

        ch_mirna_files = Channel.empty()
        ch_mirna_files = MIRALIGNER_MIRNA.out.mirna_aligned
            .map { it[1] } // Extract the file path from the tuple
            .collect() // Collect all items into a single list
        ISOMIRS_STATS(ch_mirna_files.collect())

    emit:
        mirna_mapped_files          = MIRALIGNER_MIRNA.out.mirna_aligned
        mirna_unmapped_files        = MIRALIGNER_MIRNA.out.mirna_unmapped_fastq
        mirna_counts                = MIRALIGNER_MIRNA.out.mirna_counts

        mirna_canonical_tsv         = ISOMIRS_STATS.out.canonical_mirna_table
        mirna_isomirs_tsv           = ISOMIRS_STATS.out.isomirs_table
}