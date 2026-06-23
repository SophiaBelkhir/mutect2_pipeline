#!/bin/bash

REF=/lustre/scratch125/casm/teams/team267_murchison/ref_genomes/Sarcophilus_Harrisii/mSarHar1_11_split/Sarcophilus_harrisii.mSarHar_split.fa
GR=/lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/110626_mutect_stage2/MergedResources/germline_resource.biallelic2.vcf.gz
PON=/lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/110626_mutect_stage2/MergedResources/panel_of_normals.vcf.gz
SCD=/lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/110626_mutect_stage2/MergedResources/somatic_candidates.vcf.gz

if [ ! -e "$REF" ]; then
  echo "Ref file not found"
  exit 1
fi

if [ ! -e "$GR" ]; then
  echo "Germline resource file not found"
  exit 1
fi

if [ ! -e "$PON" ]; then
  echo "Panel of normals file not found"
  exit 1
fi

if [ ! -e "$SCD" ]; then
  echo "Somatic candidates file not found"
  exit 1
fi

#echo "Normalising germline resource..."
#bcftools norm -m -both -f $REF $GR \
#        | bcftools view -Oz -o gr.vcf.gz -S ^<(bcftools query -l $GR)
#bcftools index -t gr.vcf.gz
#echo "Normalising panel of normals..."
#bcftools norm -m -both -f $REF $PON \
#        | bcftools view -Oz -o pon.vcf.gz -S ^<(bcftools query -l $PON)
#bcftools index -t pon.vcf.gz

echo "Normalising somatic candidates..."
bcftools norm -m -both -f $REF $SCD \
        | bcftools view -Oz -o sc.vcf.gz -S ^<(bcftools query -l $SCD)
bcftools index -t sc.vcf.gz

echo "Finalising the somatic candidates..."
bcftools concat -a -d exact gr.vcf.gz pon.vcf.gz sc.vcf.gz \
        | bcftools view -e 'TYPE="indel" && strlen(REF) - strlen(ALT) > 150' \
        | bcftools view -e 'ALT="*"' \
        | bcftools sort \
        | bcftools norm -f $REF \
        | bcftools norm -d exact \
        | bcftools annotate -x INFO,QUAL -Oz -o candidates.vcf.gz
bcftools index -t candidates.vcf.gz

echo "Done! Output written to candidates.vcf.gz"

rm gr.vcf.gz* pon.vcf.gz* sc.vcf.gz*

# prepare the format of the candidates vcf file for bcftools mpileup
bcftools query -f'%CHROM\t%POS\t%REF,%ALT\n' candidates.vcf.gz | bgzip -c > bcftools_candidates.tsv.gz && tabix -s1 -b2 -e2 bcftools_candidates.tsv.gz
