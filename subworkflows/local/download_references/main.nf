//
// Subworkflow with functionality specific to the ktrachtova/perseqpipe pipeline
//
// This subworkflow contains code for download of reference files
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PROCESS TO DOWNLOAD REFERENCE FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
process DOWNLOAD_REFERENCE_FILES {
    tag "Download reference files"
    publishDir '.', mode: 'copy', overwrite: true

    input:
    val index_url
    val index_path
    val gtf_url
    val gtf_path
    val mirna_url
    val mirna_path

    output:
    path "${index_path}", emit: star_index_dir
    path "${gtf_path}", optional: true, emit: gtf_file
    path "${mirna_path}", optional: true, emit: mirna_path

    script:

    def index_folder = index_path.toString().tokenize('/').last()
    def gtf_file_name = gtf_path ? gtf_path.toString().tokenize('/').last() : null
    def mirna_file_name = mirna_path ? mirna_path.toString().tokenize('/').last() : null

    """
    mkdir -p resources
    cd resources

    echo "Downloading STAR index from ${index_url}"
    wget -S --max-redirect=20 --tries=10 --waitretry=30 --timeout=60 --retry-connrefused ${index_url} -O ${index_folder}.tar.gz
    tar -xzf ${index_folder}.tar.gz
    rm ${index_folder}.tar.gz
 
    if [ ! -z "${gtf_url}" ]; then
        echo "Downloading GTF from ${gtf_url}"
        wget -q ${gtf_url} -O ${gtf_file_name}.gz
        gunzip -f ${gtf_file_name}.gz
    fi

    if [ ! -z "${mirna_url}" ]; then
        echo "Downloading miRNA overlap static file from ${mirna_url}"
        wget -q ${mirna_url} -O ${mirna_file_name}
    fi
    """
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO DOWNLOAD REFERENCE FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow DOWNLOAD_REFERENCES {
    take:
        index_url
        index_path
        gtf_url
        gtf_path
        mirna_url
        mirna_path

    main:
    DOWNLOAD_REFERENCE_FILES(index_url, index_path, gtf_url, gtf_path, mirna_url, mirna_path)
}