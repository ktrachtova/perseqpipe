process STAR_GENOME {
    tag "$meta.id"
    label 'process_high_memory'

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
    03c_star_genome.sh ${genome_index} ${reads} ${meta.id} $task.cpus \\
        ${params.genome_outFilterMultimapNmax} \\
        ${params.genome_outFilterMatchNmin} \\
        ${params.genome_outFilterMismatchNoverReadLmax} \\
        ${params.genome_outFilterMultimapScoreRange} \\
        ${params.genome_outFilterScoreMinOverLread} \\
        ${params.genome_outFilterMismatchNmax} \\
        ${params.genome_alignIntronMax} \\
        ${params.genome_alignIntronMin}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """
}