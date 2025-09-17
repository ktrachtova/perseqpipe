include { DESEQ2_MIRNA_ANALYSIS } from '../../../modules/local/deseq2_mirna_analysis/main'
include { DESEQ2_SRNA_ANALYSIS } from '../../../modules/local/deseq2_srna_analysis/main'

workflow DE_ANALYSIS {

    take:
        mirna_canonical_tsv
        mirna_isomirs_tsv
        srna_counts_tsv

    main:
        // Check if 'params.design_file' is defined and not null
        if (params.design_file) {
            // Create a channel from the provided design file path
            ch_design_file = Channel.fromPath(params.design_file)
        } else {
            // Create an empty channel to represent the absence of the design file
            ch_design_file = Channel.of( [] )
        }
        DESEQ2_MIRNA_ANALYSIS (
            mirna_canonical_tsv,
            mirna_isomirs_tsv,
            ch_design_file
        )
        DESEQ2_SRNA_ANALYSIS (
            srna_counts_tsv,
            ch_design_file
        )

    emit:
        deseq2_rds         = DESEQ2_MIRNA_ANALYSIS.out.deseq2_analysis_data_rds
}