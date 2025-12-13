process STAR_GENOME {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/star:2.7.11b--822039d47adf19a7'

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