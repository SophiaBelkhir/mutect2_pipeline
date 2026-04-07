nextflow.enable.dsl=2

params.reference        = "genome.fa"
params.numIntervals        = 40
params.panel_normals    = "panel_of_normals_samples_folder"
params.resource_normals = "germline_resource_samples_folder"
params.tumours          = "somatic_tumour_samples_folder"
params.outdir           = "results"

def remove_duplicate_filepair_keys(primary_ch, secondary_ch) {
    // primary_ch and secondary_ch are channels produced by
    // `fromFilePairs`. If any keys are present in both channels,
    // remove the key from the secondary channel.
    // This will avoid duplicating work on a bam file if it has
    // a bai and a csi index.
    return primary_ch.concat(secondary_ch).groupTuple()
        .map { entry -> tuple(entry[0], entry[1][0]) }
}

include { indexReference }                           from "./preprocessReference.nf"
include { makeReferenceDict }                        from "./preprocessReference.nf"
include { concatVcfParts as concatMutectTumours }    from "./vcfConcatenator.nf"
include { concatVcfParts as concatMutectNormals }    from "./vcfConcatenator.nf"
include { concatGvcfParts }                         from "./vcfConcatenator.nf"


workflow {
    /////////////////////////////////
    //         Preanalysis setup
    //

    // Load and process the reference
    ref_ch = channel.fromPath(params.reference)
    fai_ch = indexReference(ref_ch)
    dict_ch = makeReferenceDict(ref_ch)
    ref_files = ref_ch.merge(fai_ch).merge(dict_ch)


    /////////////////////////////////
    //        Concatenate and reblock vcfs from the first round of calling
    //

    // Load normal vcfs from the first round of mutect2 calling
    normals_called_by_mutect_ch = channel
        .fromFilePairs("${params.panel_normals}/*.normal.mutect2_panel_calls.vcf.gz{,.tbi}", checkIfExists: true)
        .map { id, files ->
            def sample = id.replaceFirst(/\.\d+$/, '')
            def vcf = files.find { f -> f.name.endsWith('.vcf.gz') && !f.name.endsWith('.vcf.gz.tbi') }
            def tbi = files.find { f -> f.name.endsWith('.vcf.gz.tbi') }
            tuple(sample, vcf, tbi)
        }

    // Concatenate all variant calls - all call result channels start with tuple(sample, vcf, tbi...)
    grouped_mutect_normals_ch = normals_called_by_mutect_ch
        .map { it -> tuple(it[0], it[1], it[2]) }
        .groupTuple(size: params.numIntervals)
        .map { sample, vcfs, tbis -> tuple(sample,
                                           "mutect2_normal",
                                           vcfs.sort { f -> f.name },
                                           tbis.sort { f -> f.name }) }
    grouped_mutect_normals_with_ref_ch = ref_files.combine(grouped_mutect_normals_ch)
        .map { fa, fai, dict, sample, label, vcfs, tbis ->
            tuple(sample, label, [fa, fai, dict], vcfs, tbis) }
    // Concat the parts of the vcf if they were split by interval
    concatMutectNormals(grouped_mutect_normals_with_ref_ch)


    // Load tumour vcfs from the first round of mutect2 calling
    tumours_first_called_by_mutect_ch = channel
        .fromFilePairs("${params.tumours}/*.tumour.mutect2_candidate_discovery_calls.vcf.gz{,.tbi}", checkIfExists: true)
        .map { id, files ->
            def sample = id.replaceFirst(/\.\d+$/, '')
            def vcf = files.find { f -> f.name.endsWith('.vcf.gz') && !f.name.endsWith('.vcf.gz.tbi') }
            def tbi = files.find { f -> f.name.endsWith('.vcf.gz.tbi') }
            tuple(sample, vcf, tbi)
        }

    // Concatenate all variant calls - all call result channels start with tuple(sample, vcf, tbi...)
    grouped_mutect_tumours_ch = tumours_first_called_by_mutect_ch
        .map { it -> tuple(it[0], it[1], it[2]) }
        .groupTuple(size: params.numIntervals)
        .map { sample, vcfs, tbis -> tuple(sample,
                                           "mutect2_tumour",
                                           vcfs.sort { f -> f.name },
                                           tbis.sort { f -> f.name }) }
    grouped_mutect_tumours_with_ref_ch = ref_files.combine(grouped_mutect_tumours_ch)
        .map { fa, fai, dict, sample, label, vcfs, tbis ->
            tuple(sample, label, [fa, fai, dict], vcfs, tbis) }
    // Concat the parts of the vcf if they were split by interval
    concatMutectTumours(grouped_mutect_tumours_with_ref_ch)


    // Load normal gvcfs from the first round of haplotype calling
    gvcfs_called_by_haplotypecaller_ch = channel
        .fromFilePairs("${params.resource_normals}/*.haplotypecaller.g.vcf.gz{,.tbi}", checkIfExists: true)
        .map { id, files ->
            def sample = id.replaceFirst(/\.\d+$/, '')
            def gvcf = files.find { f -> f.name.endsWith('.g.vcf.gz') && !f.name.endsWith('.g.vcf.gz.tbi') }
            def tbi = files.find { f -> f.name.endsWith('.g.vcf.gz.tbi') }
            tuple(sample, gvcf, tbi)
        }

    // Concatenate all variant calls - all call result channels start with tuple(sample, vcf, tbi...)
     grouped_haplotypecaller_ch = gvcfs_called_by_haplotypecaller_ch
        .map { it -> tuple(it[0], it[1], it[2]) }
        .groupTuple(size: params.numIntervals)
        .map { sample, vcfs, tbis -> tuple(sample,
                                           "haplotypecaller_normal",
                                           vcfs.sort { f -> f.name },
                                           tbis.sort { f -> f.name }) }
    grouped_haplotypecaller_with_ref_ch = ref_files.combine(grouped_haplotypecaller_ch)
        .map { fa, fai, dict, sample, label, vcfs, tbis ->
            tuple(sample, label, [fa, fai, dict], vcfs, tbis) }
    // Concat and reblock the gvcf parts if they were split by interval
    concatGvcfParts(grouped_haplotypecaller_with_ref_ch)
}

// This workflow only performs the interval-wise concatenation/reblocking step.
// The resulting combined files are published under params.outdir/CombinedCalls/