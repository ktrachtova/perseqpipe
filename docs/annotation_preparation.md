# Annotation preparation

## Table of Contents
- [rRNA](#rrna)
- [tRNA](#trna)
- [snoRNA](#snorna)
- [piRNA](#pirna)
- [other RNA](#other-rna)
- [Merging GTF files into final annotation GTF](#merging-gtf-files-into-final-annotation-gtf)
- [sncRNA GTF file format](#sncrna-gtf-file-format)

This section describes the exact steps used to create the annotation GTF file for sncRNA quantification. It can also serve as a guide for re-creating the annotation GTF file from scratch.

> [!IMPORTANT]
> The main annotation GTF file to use in the PerSeqPIPE **SNCRNA_QUANTIFICATION** module is pre-build and does NOT have to be created by the user! 

The raw files used to build databases for each sncRNA class are available at Zenodo [here](https://zenodo.org/records/18277990). These files can be used to prepare sequence databases for each sncRNA class following the instructions below—simply download the compressed archive from Zenodo, unzip it, and locate the appropriate files for each RNA class. Code that was used for preprocessing of the raw database files is available in repositoy [Reference Preparation](https://github.com/ktrachtova/reference_preparation).

> [!CAUTION]
> The annotation preparation process is not part of the main PerSeqPIPE code, as it requires manual execution with frequent verification of results at each step. Because the FASTA files used to generate the sncRNA GTF are obtained from public databases, their formats may change in future releases; therefore, a manual procedure is required to ensure consistency and accuracy.

## rRNA

```
# download docker image with all required dependencies, the docker image is loaded inside the script automatically
docker pull ktrachtok/reference_preparation:x86_64-1.0

# download repository with code
git clone https://github.com/ktrachtova/reference_preparation.git

# run create_rrna_database.sh with own original raw files (replace by your own if rebuilding with updated resources);
# DB1=RNACentral FASTA; DB2=NCBI FASTA
cd reference_preparation/perseqpipe/scripts

./create_rrna_database.sh \
--DB1 /path/to/rRNA_RNACentral_v24.fasta.gz \
--DB2 /path/to/rRNA_NCBI.fasta.gz
```

The script creates a directory in reference_preparation repository folder, under path `reference_preparation/perseqpipe/reference_files/rRNA/YYYY_DD_MM` with files:
* `rRNA_db_custom.fa`: final FASTA file with cleaned and processed rRNA sequences
* `rRNA_cluster_results.tsv`: file with cluster results; first column shows ID of cluster reference sequences, second correspond to all sequence IDs forming the cluster

Exact steps in processing rRNA sequences:
1. convert resource FASTA files from multi-line to one-line
2. merge FASTA files
3. identify clusters with 100% identity (complete coverage) with MMseqs2 in order to remove redundant sequences
3. run custom Python script to create FASTA file based on clustering results; for rRNA sequences only one ID (the reference ID from MMseqs2) was used as a header for each sequence, to explore all IDs that form one cluster (=identical sequences), please explore file rRNA_cluster_results.tsv

To use the created rRNA FASTA file for rRNA contamination removal in PerSeqPIPE workflow, you have to create a new STAR index with this FASTA file. Example command:
```
STAR  --runMode genomeGenerate \
--runThreadN 4  \
--genomeDir star_rrna_custom/  \
--genomeFastaFiles rRNA_db_custom.fa \
--genomeSAindexNbases 2
```

Then, supply the created STAR index folder (in the code above folder `star_rrna_custom/`) to the PerSeqPIPE.

> [!WARNING]
> Be aware that versions of STAR need to be identical for both creating an index and running actual STAR aligner inside PerSeqPIPE! Version of STAR currently used by PerSeqPIPE can be found in the [`main.nf`](https://github.com/ktrachtova/perseqpipe/blob/main/modules/local/star_align_rrna/main.nf) file of `star_rrna` module.


## tRNA

In order to prepare tRNA sequences, a primary assembly FASTA file must be first downloaded. This file is available at [GENCODE website](https://www.gencodegenes.org/human/). Version should be identical to version of the input GENCODE transcript file (in example below we use file `gencode.v47.transcripts.fa`, hence it is recommended to use identical version of primary assembly FASTA to ensure reproducibility.) Older versions of Gencode files can be downloaded from their [FTP site](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/). 

> [!NOTE]
> All input files for script `./create_trna_database.sh` can be provided as either `.fa` or `.fa.gz`. However, note that in case of using compressed files (especially compressed primary assembly FASTA), decompression will take some time which will prolong the runtime of the script.


```
# download docker image with all required dependencies, the docker image is loaded inside the script automatically
docker pull ktrachtok/reference_preparation:x86_64-1.0

# download repository with code
git clone https://github.com/ktrachtova/reference_preparation.git

# change directory into the repo scripts/ folder
cd reference_preparation/perseqpipe/scripts

# run create_trna_database.sh with original raw files (replace by your own if rebuilding with updated resources);
# DB1=GENCODE FASTA; DB2=GtRNAdb BED; DB3=GtRNAdb filtered FASTA; DB4=GtRNAdb mature FASTA; (optional) GENOME=GrCh38 primary assembly FASTA, if not provided GENOME is downloaded from Gencode automatically (might take several minutes to download)
./create_trna_database.sh \
--DB1 /path/to/gencode.v47.transcripts.fa \
--DB2 /path/to/hg38-tRNAs.bed \                     
--DB2_FASTA1 /path/to/hg38-filtered-tRNAs.fa \     
--DB2_FASTA2 /path/to/hg38-mature-tRNAs.fa \
--GENOME /path/to/GRCh38.primary_assembly.genome.fa
```

The script creates a directory in the reference_preparation repository, under path `reference_preparation/perseqpipe/reference_files/tRNA/{YYYY_DD_MM}` with files:
* `tRNA_db_custom_genomeMap.gtf`: GTF file with tRNA coordinates
* `tRNA_db_custom.fa`: final FASTA with all tRNA sequences
* `tRNA_db_custom_genomeMap.bed`: BED file with tRNA coordinates
* `mt_tRNA_db_genomeMap.psl`: PSL file for mt-tRNA 
* `mt_tRNA_db_genomeMab.bed`: BED file for mt-tRNA

Exact steps in processing tRNA sequences:
1. convert Gencode FASTA from multi-line to one-line
2. extract mt-tRNA sequences from Gencode FASTA file (gene biotype `Mt_tRNA`)
3. convert both GtRNAdb FASTA files from multi-line to one-line
4. for both GtRNAdb FASTA files and Gencode mt-tRNA FASTA file, convert Us->Ts
5. align mt-tRNA FASTA file to human genome with Blat
6. convert mt-tRNA PSL file from Blat to BED
7. merge GtRNAdb BED files with mt-tRNA BED
8. convert final BED to GTF
9. merge all 3 cleaned FASTA files to create final FASTA file

The resulting GTF file is merged with GTF files of all other sncRNA classes to form the final annotation GTF file for PerSeqPIPE.

## snoRNA

In order to prepare snoRNA sequences, a primary assembly FASTA file must be first downloaded. This file is available at [GENCODE website](https://www.gencodegenes.org/human/). Version should be identical to version of the input GENCODE transcript file (in example below we use file `gencode.v47.transcripts.fa`, hence it is recommended to use identical version of primary assembly FASTA to ensure reproducibility.) Older versions of Gencode files can be downloaded from their [FTP site](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/). 

> [!NOTE]
> All input files for script `./create_snorna_database.sh` can be provided as either `.fa` or `.fa.gz`. However, note that in case of using compressed files (especially compressed primary assembly FASTA), decompression will take some time which will prolong the runtime of the script.

```
# download docker image with all required dependencies, the docker image is loaded inside the script automatically
docker pull ktrachtok/reference_preparation:x86_64-1.0

# download repository with code
git clone https://github.com/ktrachtova/reference_preparation.git

# change directory into the repo scripts/ folder
cd reference_preparation/perseqpipe/scripts

# run create_snorna_database.sh with raw FASTA files;
# DB1=RNACentral FASTA; DB2=Gencode FASTA;GENOME=GrCh38 primary assembly FASTA (optional), if not provided it is downloaded from Gencode automatically (might take several minutes to download)
./create_snorna_database.sh \
--DB1 /path/to/snoRNA_RNACentral_v24.fasta.gz \
--DB2 /path/to/gencode.v47.transcripts.fa.gz \                     
--GENOME /path/to/GRCh38.primary_assembly.genome.fa
```

The script creates a directory in reference_preparation repository folder, under path `reference_preparation/perseqpipe/reference_files/snoRNA/YYYY_DD_MM` with files:
* `snoRNA_db_custom_genomeMap.gtf`: final GTF file
* `snoRNA_db_custom.fa`: final FASTA file with snoRNA sequences
* `snoRNA_db_custom_genomeMap.bed`: BED file
* `snoRNA_db_custom_genomeMap.psl`: PSL file from BLAT
* `snorna_databases.csv`: file listing databases and number of sequences
* `snorna_database_lenDist.csv`: length distribution of snoRNA sequences
* `snorna_cluster_result.tsv`: file with results from MMseqs2 clustering

Exact steps in processing snoRNA sequences:
1. convert resource FASTA files from multi-line to one-line
2. for RNACentral FASTA file, convert Us->Ts for all sequences
3. for Gencode FASTA file, only extract snoRNA sequences (gene biotype `snoRNA` or `scaRNA`)
4. merge both FASTA files
5. identify clusters with 100% identity (complete coverage) with MMseqs2 in order to remove redundant sequences
6. run custom Python script to create FASTA file based on clustering results; script is run with `--merge_headers` parameter so that each sequence reported in final FASTA file has header compiled from all IDs of all sequences that form given cluster (=identical sequences)
7. align final FASTA file to human genome with Blat
8. convert PSL from Blat to BED12 using custom script
9. Convert BED12 to GTF using custom script

The resulting GTF file is merged with GTF files of all other sncRNA classes to form the final annotation GTF file for PerSeqPIPE.

## piRNA


In order to prepare piRNA sequences, a primary assembly FASTA file must be first downloaded. This file is available at [GENCODE website](https://www.gencodegenes.org/human/). Version should be identical to version of the input GENCODE transcript file used to create partial GTF files for other sncRNA classes (such as tRNA or snoRNA, in examples above we use file `gencode.v47.transcripts.fa`, hence it is recommended to use identical version of primary assembly FASTA to ensure reproducibility). Older versions of Gencode files can be downloaded from their [FTP site](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/). 

> [!NOTE]
> All input files for script `./create_pirna_database.sh` can be provided as either `.fa` or `.fa.gz`. However, note that in case of using compressed files (especially compressed primary assembly FASTA), decompression will take some time which will prolong the runtime of the script.

```
# download docker image with all required dependencies, the docker image is loaded inside the script automatically
docker pull ktrachtok/reference_preparation:x86_64-1.0

# download repository with code
git clone https://github.com/ktrachtova/reference_preparation.git

# change directory into the repo scripts/ folder
cd reference_preparation/perseqpipe/scripts

# run create_pirna_database.sh with own raw FASTA files;
# DB1=RNACentral FASTA; DB2=piRBase FASTA; DB3=piRNAdb FASTA; DB4=NCBI FASTA; GENOME=GrCh38 primary assembly FASTA (optional), if not provided it is downloaded from Gencode automatically (might take several minutes to download)
./create_pirna_database.sh \
--DB1 /path/to/RNACentral_v24_piRNA.fasta.gz \
--DB2 /path/to/piRBase_v3_gold.fa.gz \
--DB3 /path/to/piRNAdb.hsa.v1_7_6.fa.gz \
--DB4 /path/to/NCBI_piRNA.fasta.gz \
--GENOME /path/to/GRCh38.primary_assembly.genome.fa
```

The script creates a directory in reference_preparation repository folder, under path `reference_preparation/perseqpipe/reference_files/piRNA/YYYY_DD_MM` with files:

* `piRNA_db_custom.fa`: final FASTA file with piRNA sequences
* `piRNA_db_custom_genomeMap.bed`: BED file
* `piRNA_db_custom_genomeMap.gtf`: final GTF file
* `piRNA_db_custom_genomeMap.psl`: PSL file from BLAT
* `pirna_databases.csv`: file listing databases and number of sequences
* `pirna_database_lenDist.csv`: length distribution of piRNA sequences
* `pirna_cluster_result.tsv`: file with results from MMseqs2 clustering

Exact steps in processing piRNA sequences:
1. merge all FASTA files together
2. convert merged FASTA file from multi-line to one-line
3. remove sequences with N nucleotides using cutadapt
4. identify clusters with 100% identity (complete coverage) with MMseqs2 in order to remove redundant sequences
5. run custom Python script to create FASTA file based on clustering results; script is run with `--merge_headers` parameter so that each sequence reported in final FASTA file has header compiled from all IDs of all sequences that form given cluster (=identical sequences)
6. align final FASTA file to human genome with Blat
7. convert PSL from Blat to BED12 using custom script
8. convert BED12 to GTF using custom script

The resulting GTF file is merged with GTF files of all other sncRNA classes to form the final annotation GTF file for PerSeqPIPE.

## other RNA

Coordinates for other, less abundant classes of sncRNA (such as snRNA, miscRNA, etc.), as well as mRNA and lncRNA, are extracted directly from the Gencode GTF file. These are then merged with the coordinates of all other sncRNA classes described above.

The following code demonstrates how to filter the Gencode GTF file for specific gene types by removing those for which reference files have already been prepared (e.g., snoRNA/scaRNA, miRNA, mt-tRNA, etc.). No additional tools or Python packages are required—only Python 3.
 
The GTF file can be download from [GENCODE website](https://www.gencodegenes.org/human/). Version should be identical to version of the input GENCODE transcript file used for creating databases of other sncRNA classes such as piRNA, snoRNA or tRNA. Older versions of Gencode files can be downloaded from their [FTP site](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/). 

```
# download repository with code
git clone https://github.com/ktrachtova/reference_preparation.git

# change directory into the repo scripts/ folder
cd reference_preparation/perseqpipe/scripts

# run prepare_other_rna.sh script to filter out Gencode GTF
./prepare_other_rna.sh \
--GTF /path/to/gencode.v47.primary_assembly.annotation.gtf
```

The script creates a directory in reference_preparation repository folder, under path `reference_preparation/perseqpipe/reference_files/other_rna/YYYY_DD_MM` with files:
* `gencode.v{XY}.primary_assembly.annotation.filtered.gtf`: filtered GTF, {XY} is version of input Gencode database

The resulting GTF file is merged with GTF files of all other sncRNA classes to form the final annotation GTF file for PerSeqPIPE.

## Merging GTF files into final annotation GTF

To create a final GTF file that is supplied to PerSeqPIPE and is used  within **SNCRNA_QUANTIFICATION** module, GTF files for all RNA classes described above have to be merged together. A simple command such as cat is sufficient to merge all GTF files into the final GTF file. Example:

```
cat  ~/reference_preparation/perseqpipe/reference_files/piRNA/2025_08_19/piRNA_db_custom_genomeMap.gtf \
     ~/reference_preparation/perseqpipe/reference_files/snoRNA/2025_08_19/snoRNA_db_custom_genomeMap.gtf \
     ~/reference_preparation/perseqpipe/reference_files/tRNA/2025_08_19/tRNA_db_custom_genomeMap.gtf \
     ~/reference_preparation/perseqpipe/reference_files/other_rna/2025_08_24/gencode.v47.primary_assembly.annotation.filtered.gtf > perseqpipe_all_sncrna_v{X.Y}.gtf
```

## sncRNA GTF file format

The sncRNA GTF file used for quantification adheres to the [standard GTF file format](https://www.ensembl.org/info/website/upload/gff.html). Chromosome identifiers include the `chr` prefix (e.g., `chr1`, `chrX`). Each sncRNA with a defined genomic locus in the human genome is represented by three feature types: gene, transcript, and exon.

If an RNA can be aligned to multiple loci within the human genome, each location record in the GTF file is distinguished by an added suffix `_loc{x}`, where `x` denotes the specific genomic occurrence of that RNA. The `gene_id` and `gene_name` attributes (as well as `transcript_id` and `transcript_name`) remain identical across all loci.

When the same RNA is present in multiple databases (for example, a piRNA found in both RNAcentral and piRNAdb), identifiers from all sources are merged into a single composite ID. For instance, a piRNA shared between RNAcentral and piRNAdb will be represented as: `URS0000000096_9606|hsa-piR-13280`.





