nextflow.enable.dsl=2

params.reference        = "genome.fa"
params.numIntervals        = 40
params.panel_normals_combined    = "panel_of_normals_combined_folder"
params.resource_normals_combined = "germline_resource_combined_folder"
params.tumours_combined          = "somatic_tumour_combined_folder"
params.outdir           = "results"

def make_db_ch(vcf_ch, tbi_ch, ivls, ref_files) {
    // Wrap collected lists in maps first so `combine` cannot flatten list
    // elements into positional tuple fields.
    def vcf_bundle = vcf_ch.collect()
        .map { vcfs -> [vcfs: vcfs.sort { a, b -> a.name <=> b.name }] }
    def tbi_bundle = tbi_ch.collect()
        .map { tbis -> [tbis: tbis.sort { a, b -> a.name <=> b.name }] }
    def files_bundle = vcf_bundle.combine(tbi_bundle)
        .map { vcfMap, tbiMap ->
            [vcfs: vcfMap.vcfs, tbis: tbiMap.tbis]
        }

    return ref_files.combine(files_bundle).combine(ivls)
        .map { fa, fai, dict, files, interval_id, interval ->
            tuple(interval_id, [fa, fai, dict], files.vcfs, files.tbis, interval)
        }
}

include { indexReference }                           from "./preprocessReference.nf"
include { makeReferenceDict }                        from "./preprocessReference.nf"
include { splitIntervals }                           from "./preprocessReference.nf"
include { genotypeGvcfIntervals }                    from "./stage2_supporting.nf"
include { makePonIntervals }                         from "./stage2_supporting.nf"
include { makeSomaticCandidatesIntervals }           from "./stage2_supporting.nf"


workflow {
    /////////////////////////////////
    //         Preanalysis setup
    //

    // Load and process the reference
    ref_ch = channel.fromPath(params.reference)
    fai_ch = indexReference(ref_ch)
    dict_ch = makeReferenceDict(ref_ch)
    ref_files = ref_ch.merge(fai_ch).merge(dict_ch)

    // Load and process the intervals (chop into intervals for scattering-gathering)
    ivls = splitIntervals(ref_files, params.numIntervals).flatten()
        .map { interval ->
            def intervalNumberMatch = interval.getName() =~ /^(\d+)/
                def intervalNumber = intervalNumberMatch ? intervalNumberMatch[0][1] : 99999
            return tuple(intervalNumber, interval) }

        // Load pre-concatenated outputs from one or more preprocessing runs.
        panel_normals_combined_ch = channel
            .fromFilePairs("${params.panel_normals_combined}/*.combined.vcf.gz{,.tbi}", checkIfExists: true)
            .map { id, files ->
                def sample = id.replaceFirst(/\.mutect2_normal$/, '')
                def vcf = files.find { f -> f.name.endsWith('.vcf.gz') && !f.name.endsWith('.vcf.gz.tbi') }
                def tbi = files.find { f -> f.name.endsWith('.vcf.gz.tbi') }
                tuple(sample, "mutect2_normal", vcf, tbi)
            }
        tumours_combined_ch = channel
            .fromFilePairs("${params.tumours_combined}/*.combined.vcf.gz{,.tbi}", checkIfExists: true)
            .map { id, files ->
                def sample = id.replaceFirst(/\.mutect2_tumour$/, '')
                def vcf = files.find { f -> f.name.endsWith('.vcf.gz') && !f.name.endsWith('.vcf.gz.tbi') }
                def tbi = files.find { f -> f.name.endsWith('.vcf.gz.tbi') }
                tuple(sample, "mutect2_tumour", vcf, tbi)
            }
        resource_normals_combined_ch = channel
            .fromFilePairs("${params.resource_normals_combined}/*.combined.g.vcf.gz{,.tbi}", checkIfExists: true)
            .map { id, files ->
                def sample = id.replaceFirst(/\.haplotypecaller_normal$/, '')
                def gvcf = files.find { f -> f.name.endsWith('.g.vcf.gz') && !f.name.endsWith('.g.vcf.gz.tbi') }
                def tbi = files.find { f -> f.name.endsWith('.g.vcf.gz.tbi') }
                tuple(sample, "haplotypecaller_normal", gvcf, tbi)
            }


     // Construct appropriate nextflow channels for stage 2
    pon_ch = make_db_ch(panel_normals_combined_ch.map { entry -> entry[2] }, panel_normals_combined_ch.map { entry -> entry[3] }, ivls, ref_files)
    som_ch = make_db_ch(tumours_combined_ch.map { entry -> entry[2] }, tumours_combined_ch.map { entry -> entry[3] }, ivls, ref_files)
    gvcf_ch = make_db_ch(resource_normals_combined_ch.map { entry -> entry[2] }, resource_normals_combined_ch.map { entry -> entry[3] }, ivls, ref_files)
       
     ///////////////////////////////////////////////////////
    //         Stage 2: Create panels and candidates

    // For each interval, create:
    // 1. A Germline Resource by running GenomicsDBImport and GenotypeGVCFs on the g.vcfs from the first round of haplotype calling
    genotypeGvcfIntervals(gvcf_ch)
    // 2. A Panel of Normals by running GenomicsDBImport and CreateSomaticPanelOfNormals on the normal vcfs from the first round of mutect2 calling
    makePonIntervals(pon_ch)
    // 3. A set of somatic candidates by running GenomicsDBImport and SelectVariants plus some normalization on the tumour vcfs from the first round of mutect2 calling
    makeSomaticCandidatesIntervals(som_ch)

}

// The final tidying up / concatenating the individual interval vcfs into single vcfs for the panel of normals and the somatic candidates 
// and finalizing the list of somatic canidates by adding all the variants from the PON and the germline resurce
// is done outside of nextflow for now, in separate scripts (folder stage2_scripts) 

