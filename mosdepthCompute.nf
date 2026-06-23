process mosdepthComputePerPos {
    tag { sample }
    
    cpus 4
    memory { 20.GB + 5.GB * (task.attempt - 1) }
    errorStrategy 'retry'
    maxRetries 2
    time '12h'
    queue 'normal'
    executor 'lsf'

    input:
    tuple val(sample), path(cram), path(crai), path(bed_file)

    output:
    path "depth_${sample}.regions.bed.gz", emit: bed_regions
    path "depth_${sample}.regions.bed.gz.csi", emit: bed_csi
    path "depth_${sample}.mosdepth.global.dist.txt", emit: global_dist
    path "depth_${sample}.mosdepth.region.dist.txt", emit: region_dist
    path "depth_${sample}.mosdepth.summary.txt", emit: summary_txt

    publishDir "${params.outdir}/normals_depth_results", mode: 'copy', pattern: '*regions.bed.gz*'

    script:
    """
    set -euo pipefail

    prefix=${sample}
    mosdepth -n -t 4 --by ${bed_file} --fast-mode -f "${params.reference}" \$prefix ${cram}

    """
}
