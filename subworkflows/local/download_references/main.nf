process DOWNLOAD_STAR_INDEX {
    tag "Download STAR index"
    publishDir '.', mode: 'copy', overwrite: true

    input:
    val index_url
    val index_path
    val gtf_url
    val gtf_path

    output:
    path "${index_path}", emit: star_index_dir
    path "${gtf_path}", optional: true, emit: gtf_file

    script:

    def index_folder = index_path.toString().tokenize('/').last()
    def gtf_file_name = gtf_path ? gtf_path.toString().tokenize('/').last() : null

    """
    mkdir -p resources
    cd resources

    echo "Downloading STAR index from ${index_url}"
    wget -q ${index_url} -O ${index_folder}.tar.gz
    tar -xzf ${index_folder}.tar.gz
    rm ${index_folder}.tar.gz
 
    if [ ! -z "${gtf_url}" ]; then
        echo "Downloading GTF from ${gtf_url}"
        wget -q ${gtf_url} -O ${gtf_file_name}.gz
        gunzip -f ${gtf_file_name}.gz
    fi
    """
}

workflow DOWNLOAD_REFERENCES {
    take:
        index_url
        index_path
        gtf_url
        gtf_path

    main:
    DOWNLOAD_STAR_INDEX(index_url, index_path, gtf_url, gtf_path)
}
