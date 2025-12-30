process ISOMIRS_STATS {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/bioconductor-isomirs_r-dplyr_r-rio:6e5ac2a348a2e87d'
    
    input:
    path miraligner_mirna

    output:
    path "canonical_mirna_counts.tsv", emit: canonical_mirna_table
    path "isomirs_counts.tsv", emit: isomirs_table

    script:
    """
    isomirs_mirna_counts.R \"${miraligner_mirna}\" ./

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(Rscript --version | cut -d' ' -f4)
    END_VERSIONS
    """
}