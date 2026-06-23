#!/bin/bash

ANALYSIS_DIR="/lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov"
PIPELINE_DIR="/lustre/scratch126/casm/staging/team267_murchison/sb71/mutect2_pipeline"
echo "Launch time: $(date)"
nextflow run ${PIPELINE_DIR}/stage3.nf \
         --reference /lustre/scratch125/casm/teams/team267_murchison/ref_genomes/Sarcophilus_Harrisii/mSarHar1_11_split/Sarcophilus_harrisii.mSarHar_split.fa \
         --normals ${ANALYSIS_DIR}/cram_files_for_stage_3/normals \
         --tumours ${ANALYSIS_DIR}/cram_files_for_stage_3/tumours \
         --samplesheet ${ANALYSIS_DIR}/cram_files_for_stage_3/samplesheet.csv \
         --germline_resource ${ANALYSIS_DIR}/MutectStage2MergedResources/germline_resource.biallelic2.vcf.gz \
         --panel_of_normals ${ANALYSIS_DIR}/MutectStage2MergedResources/panel_of_normals.vcf.gz \
         --somatic_candidates ${ANALYSIS_DIR}/MutectStage2MergedResources/candidates.vcf.gz \
         --bcftools_candidates ${ANALYSIS_DIR}/MutectStage2MergedResources/bcftools_candidates.tsv.gz \
         --bed_file_pos ${ANALYSIS_DIR}/MutectStage2MergedResources/all_candidates_positions.bed \
         --intervals 99 \
         --outdir /nfs/casm/team267_murchison/sb71 \
         -with-report \ 
         -resume \
         -config ${PIPELINE_DIR}/stage3_nextflow.config