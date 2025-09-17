process STAR_RRNA {
    tag "$meta.id"
    label 'process_high'
    
    conda "${moduleDir}/environment.yml"
    container 'biocontainers/star:2.7.11b--h5ca1c30_5'

    input:
    path rrna_index
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path ("*.Aligned.out.bam"),                emit: rrna_aligned_bam
    tuple val(meta), path ("*.Unmapped.out.fastq.gz"),          emit: rrna_unmapped_fastq
    tuple val(meta), path ("*.Log.*"),                          emit: rrna_logs

    script:
    """    
    03a_star_rrna.sh ${rrna_index} ${reads} ${meta.id} 4
    """
}