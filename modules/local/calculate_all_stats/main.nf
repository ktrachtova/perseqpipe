process CALCULATE_ALL_STATS {
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/pandas:2.3.3--5a902bf824a79745'
    
    input:
    path counts_files

    output:
    path "read_counts_summary.csv", emit: overall_statistics

    script:
    """
    calculate_statistics.py ./

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version | head -n1 | cut -d' ' -f2)
    END_VERSIONS
    """
}