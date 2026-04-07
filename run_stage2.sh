#!/bin/bash

module load ISG/singularity/

nextflow run stage2.nf \
         --reference /lustre/scratch125/casm/teams/team267_murchison/ref_genomes/Sarcophilus_Harrisii/mSarHar1_11_split/Sarcophilus_harrisii.mSarHar_split.fa \
         --panel_normals_combined /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/03_04_26_mutect2_stage2_test/CombinedCalls/mutect2_normal \
         --resource_normals_combined /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/03_04_26_mutect2_stage2_test/CombinedCalls/haplotypecaller_normal \
         --tumours_combined /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/03_04_26_mutect2_stage2_test/CombinedCalls/mutect2_tumour \
         --outdir /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/03_04_26_mutect2_stage2_test \
         --numIntervals 40 \
         -resume
