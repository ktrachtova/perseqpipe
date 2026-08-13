# PerSeqPIPE: Custom parameters

## Input / Output options

| parameter              | type   | description                                    |
| -----------------------|--------|------------------------------------------------|
| `--input_samplesheet`  | string | (Required) Path to the comma-separated file contianing sample information |
| `--outdir`             | string | (Required) The output directory where all results will be saved. |

## Module control flags

Specifying one of the following parameters is required to run PerSeqPIPE.

| parameter              | type   | description                                    |
| -----------------------|--------|------------------------------------------------|
| `--download_reference_rrna` | boolean | Download rRNA STAR index, no actual analysis will be performed |
| `--download_reference_genome` | boolean | Download human STAR index and custom sncRNA GTF file |
| `--run_firstqc` | boolean | Run only FIRSTQC module |
| `--run_preprocessing` | boolean | Run modules up to (including) PREPROCESSING module |
| `--run_rrna` | boolean | Run modules up to (including) RRNA_QUANTIFICATION |
| `--run_mirna` | boolean | Run modules up to (including) MIRNA_QUANTIFICATION |
| `--run_sncrna` | boolean | Run modules up to (including) GENOME_QUANTIFICATION |
| `--run_full` | boolean | Run all modules of the PerSeqPIPE pipeline |
| `--miraligner_db` | string | Database used for miRNA/isomiR quantification using miraligner tool, one of `['mirbase', 'mirgenedb']`. Default = `mirbase`. |

## Reference and annotation options

| parameter              | type   | description                                    |
| -----------------------|--------|------------------------------------------------|
| `--index_rrna_url`     | string | Link to .tar.gz compressed STAR rRNA index     |
| `--index_rrna_path`    | string | Path to download STAR rRNA index               |
| `--mirbase_db`         | string | Link to .tar.gz compressed miRbase database    | 
| `--mirgene_db`         | string | Link to tar.gz compressed MirGeneDB database   |      
| `--index_genome_url`   | string | Link to .tar.gz compressed STAR GRCh38 index   |
| `--index_genome_path`  | string | Path to download STAR GRCh38 index             |
| `--sncrna_gtf_url`     | string | Link to .tar.gz compressed custom sncRNA GTF   |
| `--sncrna_gtf_path`    | string | Path to downloaded custom sncRNA GTF           |

## Preprocessing options

| parameter              | type    | description                                    |
| -----------------------|---------|------------------------------------------------|
| `--lib_type`           | string  | (Required) Library type used to prepare sequencing libraries, one of `['truseq','trilink','qiaseq','nextflexV3','nextflexV4','novogene','norgen','nebnext','lexogen']` |
| `--error_rate`         | number  | Error rate for adapter trimming                |
| `--min_overlap`        | integer | Minimal overlap between adapter and read required |
| `--disc_short`         | integer | Length threshold for discarding reads          |
| `--quality_filter`     | integer | Quality filtering for preprocessing |
| `--adapter3_seq`       | string | Adapter sequence for first 3' adapter trimming |
| `--adapter3_qiaseq_seq1` | string | First 3' end adapter sequence (QIAseq-specific!) |
| `--adapter3_qiaseq_seq2` | string | Second 3' end adapter sequence (QIAseq-specific!) |

## sncRNA quantification options

| parameter              | type   | description                                    |
| -----------------------|--------|------------------------------------------------|
| `--sncrna_overlap` | integer | Minimum total number of base pairs that a read must overlap an annotated feature for the read to be counted (e.g., 5 requires at least 5 bp of overlap). Default = 5. |
| `--sncrna_overlap_frac` | number | Minimum fraction of a read’s length that must overlap an annotated feature for the read to be counted (e.g., 1.0 requires full-length overlap, 0.5 requires at least 50%). |
| `--reads_threshold` | integer | Minimal expression of a read to be counted during sncRNA quantification. Any read with expression lower than this threshold will be omitted from the sncRNA quantification results. Default = 1.|

## DE analysis options

| parameter              | type    | description                                    |
| -----------------------|---------|------------------------------------------------|
| `--design_file`        | string  | Path to the design file |
| `--sncrna_expression_threshold` | string | Expression thresholds for samples for sncRNA, e.g., '20,3' mean at least 20 reads in at least 3 samples
| `--mirna_expression_threshold` | string | Expression thresholds for samples for miRNA, e.g., '20,3' mean at least 20 reads in at least 3 samples |
| `--isomirs_expression_threshold` | string | Expression thresholds for samples for isomiRs, e.g., '20,3' mean at least 20 reads in at least 3 samples |

## MultiQC options

| parameter              | type   | description                                    |
| -----------------------|--------|------------------------------------------------|
| `--multiqc_config`     | string | Path to the MultiQC config that can be used to modify what is visualized by MultiQC |
| `--multiqc_logo`       | string | Path to the image of logo that should be visible inside MultiQC report |
| `--multiqc_methods_description` | string | Custom MultiQC yaml file with HTML including a methods description |


## Generic options

| parameter              | type   | description                                    |
| -----------------------|--------|------------------------------------------------|
| `--publish_dir_mode`   | string | How the results should be published from default `work/` directory the the ouptut directory? Default is 'copy', can be 'move' or 'symlink' as well. |
| `--miraligner_jar`     | string | Path to the miraligner.jar executable, only applicable if pipeline is run locally! |
| `--email`              | string | Exmail adress to send summary after pipeline completion |