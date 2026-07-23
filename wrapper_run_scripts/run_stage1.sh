#!/bin/bash

#22-01-2026 for 2_Max_batch
module load ISG/singularity/

nextflow run stage1.nf \
         --reference /lustre/scratch125/casm/teams/team267_murchison/ref_genomes/Sarcophilus_Harrisii/mSarHar1_11_split/Sarcophilus_harrisii.mSarHar_split.fa \
         --normals /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/021225_realigned_highcov/07_Max_samples/cram_files/normals \
         --tumours /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/021225_realigned_highcov/07_Max_samples/cram_files/tumours \
         --outdir /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/170126_mutect2_stage1_batches/07_Max_samples_150226 \
         --numIntervals 40 \
         -resume
