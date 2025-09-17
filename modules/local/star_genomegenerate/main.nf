process STAR_GENOMEGENERATE {
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container 'biocontainers/star:2.7.11b--h5ca1c30_5'

    input:
        path    fasta
        val     fasta_type // rrna or genome

    output:
        path "star_${fasta_type}", emit: star_index

    script:    
    """
    if [[ "$fasta_type" == "rrna" ]]
    then
        star_rrna_index.sh ${fasta}
    else
        star_genome_index.sh ${fasta}
    fi
    """

}