process DOWNLOAD_STAR_INDEX {
    tag "Download STAR index"
    publishDir '.', mode: 'copy', overwrite: true

    input:
    val index_url
    val index_name
    val output_dir

    output:
    path "${output_dir}", emit: star_index_dir

    script:
    """
    mkdir -p resources
    cd resources

    if [ ! -d "${index_name}" ]; then
        echo "Downloading STAR index from ${index_url}"
        wget -q ${index_url} -O ${index_name}.tar.gz
        tar -xzf ${index_name}.tar.gz
        rm ${index_name}.tar.gz
    else
        echo "Index already exists, skipping download."
    fi
    """
}

workflow DOWNLOAD_REFERENCES {
    take:
        index_url
        index_name
        reference_type

    main:
    DOWNLOAD_STAR_INDEX(index_url, index_name, reference_type)
}
