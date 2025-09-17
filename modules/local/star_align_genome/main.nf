process STAR_GENOME {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container 'biocontainers/star:2.7.11b--h5ca1c30_5'

    maxForks 1  // Limits this process to a max of 2 concurrent instances

    input:
    path genome_index
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path ("*.Aligned.sortedByCoord.out.bam"),  emit: genome_aligned_bam
    tuple val(meta), path ("*.genome.unmapped.out.fastq.gz"),   emit: genome_unmapped_fastq
    tuple val(meta), path ("*.Log.*"),                          emit: genome_logs

    script:
    """
    03e_star_genome.sh ${genome_index} ${reads} ${meta.id}
    """
}