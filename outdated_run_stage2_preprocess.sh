#!/bin/bash

module load ISG/singularity/

nextflow run stage2_preprocess.nf \
         --reference /lustre/scratch125/casm/teams/team267_murchison/ref_genomes/Sarcophilus_Harrisii/mSarHar1_11_split/Sarcophilus_harrisii.mSarHar_split.fa \
         --panel_normals /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/02_04_26_stage1_outputs_staging/InitialNormalMutectCalls \
         --resource_normals /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/02_04_26_stage1_outputs_staging/InitialNormalHaplotypeCallerCalls \
         --tumours /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/02_04_26_stage1_outputs_staging/InitialTumourMutectCalls \
         --outdir /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/03_04_26_mutect2_stage2_test \
         --numIntervals 90 \
         -resume