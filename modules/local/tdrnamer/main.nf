process TDRNAMER {
    tag "$meta.id"
    label 'process_single'

    container 'ktrachtok/tdrnamer:1.3.1-procps'

    input:
    tuple val(meta), path(srna_counts_tsv)
    val   tdrnamer_db_url
    val   tdrnamer_db_name
    path  mirna_overlap


    output:
    tuple val(meta), path ("*.short_rna_counts.tsv"), emit: tdr_annotated_tsv
    path mirna_overlap, emit: mirna_overlap

    script:
    def prefix = task.ext.prefix ?: meta.id
    """
    # tdrnamer image lacks 'ps', which nextflow needs to collect task metrics
    command -v ps >/dev/null 2>&1 || (apt-get update -qq && apt-get install -y -qq procps >/dev/null 2>&1) || true

    wget -q ${tdrnamer_db_url} -O tdrnamer_db.tar.gz
    tar -xzf tdrnamer_db.tar.gz

    03f_tdrnamer.py \\
        --srna_counts_tsv ${srna_counts_tsv} \\
        --db ${tdrnamer_db_name}/${tdrnamer_db_name} \\
        --source euk \\
        --output_prefix ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tDRnamer: \$(tDRnamer --version 2>&1 | head -n1 || echo "unknown")
    END_VERSIONS
    """
}
