process MIRALIGNER_MIRNA {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container 'rna_quantification:1.0.0'
    
    input:
    path miraligner_db
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path ("*.mirna"),                   emit: mirna_aligned
    tuple val(meta), path ("*.mirna.unmapped.fastq.gz"), emit: mirna_unmapped_fastq
    tuple val(meta), path ("*.counts.txt"),              emit: mirna_counts

    script:

    def db_dir = miraligner_db.toString().replaceFirst(/\.tar\.gz$/, '')

    """
    tar -zxvf ${miraligner_db}
    03c_miraligner_mirna.sh ${db_dir} ${reads} ${meta.id} ${params.miraligner_jar}
    """
}