process ALIGNMENT_STATS {
    tag "$meta.id"
    label 'process_low'
    
    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/samtools:1.21--0d76da7c3cf7751c'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path ("*.counts.txt"), emit: counts

    script:
    def prefix = bam.baseName.replaceAll(/\.Aligned\..*/, "")
    """
    # Get number of counts -> take from BAM file based on read names that contain real number of reads before pre-alignment collapsing
    # rRNA unmapped
    # samtools view $bam | grep -w 'NH:i:0' | cut -f1 | cut -d'x' -f2 | awk '{s+=\$1} END {print s}' > ${prefix}.unmapped.counts.txt
    samtools view $bam | (grep -w 'NH:i:0' || true) | cut -f1 | cut -d'x' -f2 | awk '{s+=\$1} END {if (NR>0) print s; else print 0}' > ${prefix}.unmapped.counts.txt

    # rRNA uniquely mapped
    # samtools view $bam | grep -w 'NH:i:1' | cut -f1 | cut -d'x' -f2 | awk '{s+=\$1} END {print s}' > ${prefix}.uniq.counts.txt
    samtools view $bam | (grep -w 'NH:i:1' || true) | cut -f1 | cut -d'x' -f2 | awk '{s+=\$1} END {if (NR>0) print s; else print 0}' > ${prefix}.uniq.counts.txt

    # rRNA multi-mapped
    # samtools view $bam | grep -v -w 'NH:i:1' | grep -v -w 'NH:i:0' | cut -f1 | sort | uniq | cut -d'x' -f2 | awk '{s+=\$1} END {print s}' > ${prefix}.multi.counts.txt
    samtools view $bam | (grep -v -w 'NH:i:0' | grep -v -w 'NH:i:1' || true) | cut -f1 | sort | uniq | cut -d'x' -f2 | awk '{s+=\$1} END {if (NR>0) print s; else print 0}' > ${prefix}.multi.counts.txt
    """
}