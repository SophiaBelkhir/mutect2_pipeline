#!/bin/bash
set -euo pipefail
module load ISG/IRODS/1.0
iinit

TSV_BATCH=$1

if [[ -z "$TSV_BATCH" ]]; then
    echo "Error: TSV batch file not provided. Usage: $0 <tsv_batch_file>"
    exit 1
fi

# First, run the script to generate samplesheet.csv and get on disk tumour and normal samples
bash /lustre/scratch126/casm/staging/team267_murchison/sb71/scripts/download_and_build_samplesheet.sh "${TSV_BATCH}"

stamp=$(date +%Y%m%d)
samplesheet="samplesheet_${stamp}.csv"

if [[ ! -f "${samplesheet}" ]]; then
    echo "Error: samplesheet file '${samplesheet}' not found. Exiting."
    exit 1
fi

# Second, run the nextflow pipeline for stage 3

module load ISG/singularity/
# Define the analysis directory and pipeline directory
ANALYSIS_DIR="/lustre/scratch126/casm/staging/team267_murchison/sb71/MutectStage3"
PIPELINE_DIR="/lustre/scratch126/casm/staging/team267_murchison/sb71/mutect2_pipeline"

# Run the Nextflow pipeline for stage 3
echo "Launch time: $(date)"
nextflow run ${PIPELINE_DIR}/stage3.nf \
         --reference /lustre/scratch125/casm/teams/team267_murchison/ref_genomes/Sarcophilus_Harrisii/mSarHar1_11_split/Sarcophilus_harrisii.mSarHar_split.fa \
         --normals ${ANALYSIS_DIR}/normals \
         --tumours ${ANALYSIS_DIR}/tumours \
         --samplesheet ${ANALYSIS_DIR}/"${samplesheet}" \
         --germline_resource ${ANALYSIS_DIR}/MutectStage2MergedResources/germline_resource.biallelic2.vcf.gz \
         --panel_of_normals ${ANALYSIS_DIR}/MutectStage2MergedResources/panel_of_normals.vcf.gz \
         --somatic_candidates ${ANALYSIS_DIR}/MutectStage2MergedResources/candidates.vcf.gz \
         --bcftools_candidates ${ANALYSIS_DIR}/MutectStage2MergedResources/bcftools_candidates.tsv.gz \
         --intervals 99 \
         --outdir /nfs/casm/team267_murchison/sb71/stage3_final \
         -with-report \
         -resume \
         -config ${PIPELINE_DIR}/stage3_nextflow.config