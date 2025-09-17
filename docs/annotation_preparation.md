# Annotation preparation

>❗**NOTE**: The main annotation GTF file to use in the PerSeqPIPE **GENOME_QUANTIFICATION** module is pre-build and and does NOT have to be created by the user! 

This section describes exact steps and gives concrete commands on how to re-create / re-build the annotation GTF file for sncRNAs used by PerSeqPIPE. 

Raw files used to build databases for each ncRNA class are available at this link. These can be used to prepare a sequence database for each sncRNA class as described by instructions below, just download the compressed folder, unzip and locate appropriate files for each sncRNA class.

>💡 **NOTE:** The annotation preparation is not part of the PerSeqPIPE main code as it requires manual approach with frequent checks of results after main steps, due to changes in format in inputs which comes from public databases where we cannot guarantee constitency. 

## rRNA

```
# download docker image with all required dependencies, the docker image is loaded inside the scripts and does not require any further modifications
docker pull ktrachtok/reference_preparation

# download repository with code
git clone https://github.com/ktrachtova/reference_preparation.git

# run create_rrna_database.sh with own original raw files (replace by your own if rebuilding with updated resources);
# DB1=RNACentral FASTA; DB2=NCBI FASTA
cd reference_preparation/perseqpipe/scripts

./create_rrna_database.sh \
--DB1 /path/to/RNACentral.fasta.gz \
--DB2 /path/to/NCBI.fasta.gz
```

The script creates a directory in reference_preparation repository folder, under path `reference_preparation/perseqpipe/reference_files/rRNA/YYYY_DD_MM` with files:
* **rRNA_db_custom.fa**: final FASTA file with cleaned and processed rRNA sequences
* rRNA_cluster_results.tsv: file with cluster results; first column shows ID of cluster reference sequences, second correspond to all sequence IDs forming the cluster

Exact steps in processing rRNA sequences:
1. convert resource FASTA files from multi-line to one-line
2. merge FASTA files
3. identify clusters with 100% identity (complete coverage) with MMseqs2 in order to remove redundant sequences
3. custom Python script to create FASTA file based on clustering results; for rRNA sequences only one ID (the reference ID from MMseqs2) was used as a header for each sequence, to explore all IDs that form one cluster (=identical sequences), please explore file rRNA_cluster_results.tsv

To use the created rRNA FASTA file for rRNA contamination removal in PerSeqPIPE workflow, you have to create a new STAR index with this FASTA file. Example command:
```
STAR  --runMode genomeGenerate \
--runThreadN 4  \
--genomeDir star_rrna_custom/  \
--genomeFastaFiles rRNA_db_custom.fa \
--genomeSAindexNbases 2
```

Then, supply the created STAR index folder (in the code above folder `star_rrna_custom/`) to the PerSeqPIPE.

>❗**NOTE**: Be aware that versions of STAR need to be identical for both creating an index and running actual STAR aligner inside PerSeqPIPE.

## tRNA
```
# download docker with all required dependencies, the docker image is loaded inside the scripts and do not require any modifications of mounted volumes etc.
docker pull ktrachtok/reference_preparation

# download repository with code
git clone https://github.com/ktrachtova/reference_preparation.git

# change directory into the repo scripts/ folder
cd reference_preparation/perseqpipe/scripts

# run create_trna_database.sh with own original raw files (replace by your own if rebuilding with updated resources);
# DB1=GENCODE FASTA; DB2=GtRNAdb BED; DB3=GtRNAdb filtered FASTA; DB4=GtRNAdb mature FASTA; (optional) GENOME=GrCh38 primary assembly FASTA, if not provided GENOME is downloaded from Gencode automatically (might take several minutes to download)
./create_trna_database.sh \
--DB1 /path/to/gencode.v47.transcripts.fa \
--DB2 /path/to/hg38-tRNAs.bed \                     
--DB2_FASTA1 /path/to/hg38-filtered-tRNAs.fa \     
--DB2_FASTA2 /path/to/hg38-mature-tRNAs.fa \
--GENOME /path/to/GRCh38.primary_assembly.genome.fa
```
The script creates a directory in the reference_preparation repository, under path `reference_preparation/perseqpipe/reference_files/tRNA/{YYYY_DD_MM}` with files:
* **tRNA_db_custom_genomeMap.gtf**: GTF file with tRNA coordinates
* tRNA_db_custom.fa: final FASTA with all tRNA sequences
* tRNA_db_custom_genomeMap.bed: BED file with tRNA coordinates
* mt_tRNA_db_genomeMap.psl: PSL file for mt-tRNA 
* mt_tRNA_db_genomeMab.bed: BED file for mt-tRNA

Exact steps in processing tRNA sequences:
1. Convert Gencode FASTA from multi-line to one-line
2. Extract mt-tRNA sequences from Gencode FASTA file (gene biotype `Mt_tRNA`)
3. Convert both GtRNAdb FASTA files from multi-line to one-line
4. For both GtRNAdb FASTA files and Gencode mt-tRNA FASTA file, convert Us->Ts
5. Align mt-tRNA FASTA file to human genome with Blat
6. Convert mt-tRNA PSL file from Blat to BED
7. Merge GtRNAdb BED files with mt-tRNA BED
8. Convert final BED to GTF
9. Merge all 3 cleaned FASTA files to create final FASTA file

The resulting GTF file is merged with GTF files of all other sncRNA classes to form the final annotation GTF file for PerSeqPIPE.

## snoRNA
```
# download docker with all required dependencies, the docker image is loaded inside the scripts and do not require any modifications of mounted volumes etc.
docker pull ktrachtok/reference_preparation

# download repository with code
git clone https://github.com/ktrachtova/reference_preparation.git

# change directory into the repo scripts/ folder
cd reference_preparation/perseqpipe/scripts

# run create_snorna_database.sh with own raw FASTA files;
# DB1=RNACentral FASTA; DB2=Gencode FASTA;GENOME=GrCh38 primary assembly FASTA (optional), if not provided it is downloaded from Gencode automatically (might take several minutes to download)
./create_snorna_database.sh \
--DB1 /path/to/snoRNA_RNACentral_v24.fasta.gz \
--DB2 /path/to/gencode.v47.transcripts.fa.gz \                     
--GENOME /path/to/GRCh38.primary_assembly.genome.fa
```
The script creates a directory in reference_preparation repository folder, under path `reference_preparation/perseqpipe/reference_files/snoRNA/YYYY_DD_MM` with files:
* **snoRNA_db_custom_genomeMap.gtf**: final GTF file
* snoRNA_db_custom.fa: final FASTA file with snoRNA sequences
* snoRNA_db_custom_genomeMap.bed: BED file
* snoRNA_db_custom_genomeMap.psl: PSL file from BLAT
* snorna_databases.csv: file listing databases and number of sequences
* snorna_database_lenDist.csv: length distribution of snoRNA sequences
* snorna_cluster_result.tsv: file with results from MMseqs2 clustering

Exact steps in processing snoRNA sequences:
1. convert resource FASTA files from multi-line to one-line
2. for RNACentral FASTA file, convert Us->Ts for all sequences
3. for Gencode FASTA file, only extract snoRNA sequences (gene biotype `snoRNA` or `scaRNA`)
4. merge both FASTA files
5. identify clusters with 100% identity (complete coverage) with MMseqs2 in order to remove redundant sequences
6. custom Python script to create FASTA file based on clustering results; script is run with `--merge_headers` parameter so that each sequence reported in final FASTA file has header compiled from all IDs of all sequences that form given cluster (=identical sequences)
7. align final FASTA file to human genome with Blat
8. convert PSL from Blat to BED12 using custom script
9. Convert BED12 to GTF using custom script

The resulting GTF file is merged with GTF files of all other sncRNA classes to form the final annotation GTF file for PerSeqPIPE.




