#!/bin/bash

PYSCRIPT="/lustre/scratch126/casm/staging/team267_murchison/sb71/mutect2_pipeline/stage2_scripts/fix_tumor_sample_in_somatic_candidates_vcf_header.py"

#for vcf in *.somatic_candidates.vcf.gz; do
#    echo "Indexing $vcf..."
#    bcftools index -f -t "$vcf"
#done

#echo "Indexed all somatic candidate VCFs. Now concatenating..."
#bcftools concat -a -D *.vcf.gz | bcftools sort -Oz -o somatic_candidates_pre_fix.vcf.gz
#echo "Concatenated somatic candidates VCF created: somatic_candidates_pre_fix.vcf.gz"
bcftools index -t somatic_candidates_pre_fix.vcf.gz
$PYSCRIPT somatic_candidates_pre_fix.vcf.gz somatic_candidates.vcf.gz
echo "Fixed tumor sample name in VCF header. Output written to somatic_candidates.vcf.gz"
bcftools index -t somatic_candidates.vcf.gz
rm somatic_candidates_pre_fix.vcf.gz somatic_candidates_pre_fix.vcf.gz.tbi

