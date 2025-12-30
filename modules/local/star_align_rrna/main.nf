process STAR_RRNA {
    tag "$meta.id"
    label 'process_high'
    
    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/star:2.7.11b--822039d47adf19a7'

    input:
    path rrna_index
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path ("*.Aligned.out.bam"),                emit: rrna_aligned_bam
    tuple val(meta), path ("*.Unmapped.out.fastq.gz"),          emit: rrna_unmapped_fastq
    tuple val(meta), path ("*.Log.*"),                          emit: rrna_logs

    script:
    """    
    03a_star_rrna.sh ${rrna_index} ${reads} ${meta.id} $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """
}