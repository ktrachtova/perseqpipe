process PREPROCESSING_RAW_READS {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/bbmap_cutadapt_fastx_toolkit_pip_gunzip:b9e0f3b085723453'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path ("intermediate_files/*/*.fastq.gz"),                          emit: intermediates
    tuple val(meta), path ("intermediate_files/*/*/*.fastq.gz"),                        emit: intermediates_discarded
    tuple val(meta), path ("${meta.id}.cleaned.fastq.gz"),                              emit: cleaned_reads
    tuple val(meta), path ("intermediate_files/*/len_distributions/*.lenDist.txt"),     emit: len_distributions
    path  "versions.yml",                                                               emit: versions

    script:    
    if (params.lib_type == 'qiaseq') {

        command="02a_preprocessing_qiaseq.sh ${reads} ${task.cpus} ${params.error_rate} ${params.min_overlap} ${params.disc_short} ${params.quality_filter} ${params.adapter3_qiaseq_seq1} ${params.adapter3_qiaseq_seq2}"

    } else if (params.lib_type in ['truseq', 'trilink', 'nextflexV4', 'lexogen', 'norgen']) {

        def adapter = params.adapter3_seq ?: 'TGGAATTCTCGGGTGCCAAGG'
        command="02a_preprocessing_truseq.sh ${reads} ${task.cpus} ${params.error_rate} ${params.min_overlap} ${params.disc_short} ${params.quality_filter} ${adapter}"
        
    } else if (params.lib_type == 'nextflexV3') {

        def adapter = params.adapter3_seq ?: 'TGGAATTCTCGGGTGCCAAGG'
        command="02a_preprocessing_nextflexV3.sh ${reads} ${task.cpus} ${params.error_rate} ${params.min_overlap} ${params.disc_short} ${params.quality_filter} ${adapter}"

    } else if (params.lib_type in ['nebnext', 'novogene']) {

        def adapter = params.adapter3_seq ?: 'AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC'
        command="02a_preprocessing_truseq.sh ${reads} ${task.cpus} ${params.error_rate} ${params.min_overlap} ${params.disc_short} ${params.quality_filter} ${adapter}"

    }
    """
    ${command}

    change_header_format.py "${reads.simpleName}.cleaned.fastq"

    gzip "${reads.simpleName}.cleaned.fastq"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cutadapt: \$(cutadapt --version)
        bbmap: \$(bbversion.sh)
        fastx_toolkit: \$(fastx_collapser -h | sed -n 's/.*FASTX Toolkit \\([0-9.]*\\).*/\\1/p')
        gunzip: \$(gunzip -V | awk 'NR==1 {print \$2}')
    END_VERSIONS
    """
}