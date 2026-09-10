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
include { MIRALIGNER_MIRNA    } from '../../../modules/local/miraligner_mirna/main'
include { ISOMIRS_STATS       } from '../../../modules/local/isomirs_stats/main'
include { DOWNLOAD_REFERENCES } from '../download_references/main.nf'
include { resolveRefPath; isMirnaDbComplete } from '../utils_perseqpipe/main.nf'

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
        def mirna_db_url
        def mirna_db_path
        def mirna_species
        if (params.miraligner_db == 'mirgenedb') {
            mirna_db_url  = params.mirgenedb_db
            mirna_db_path = params.mirgenedb_db_path
            mirna_species = 'Hsa'
        } else if (params.miraligner_db == 'mirbase') {
            mirna_db_url  = params.mirbase_db
            mirna_db_path = params.mirbase_db_path
            mirna_species = 'hsa'
        } else {
            error "Invalid value for params.miraligner_db: '${params.miraligner_db}'. Must be one of ['mirbase', 'mirgenedb']."
        }

        // Use the pre-downloaded miRNA database if already present, otherwise download it now
        def mirna_db_dir = resolveRefPath(mirna_db_path)

        if (isMirnaDbComplete(mirna_db_dir)) {
            ch_mirna_db = channel.value(mirna_db_dir)
        } else {
            DOWNLOAD_REFERENCES('', '', '', '', '', '', mirna_db_url, mirna_db_path)
            ch_mirna_db = DOWNLOAD_REFERENCES.out.mirna_db_dir
        }

        MIRALIGNER_MIRNA(ch_mirna_db, mirna_species, cleaned_reads)

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