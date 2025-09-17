process CALCULATE_ALL_STATS {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'biocontainers/pandas:2.2.1'
    
    input:
    path counts_files

    output:
    path "read_counts_summary.csv", emit: overall_statistics

    script:
    """
    calculate_statistics.py ./
    """
}