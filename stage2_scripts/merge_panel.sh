#!/bin/bash

bcftools concat -a -D *.vcf.gz | bcftools sort -Oz -o panel_of_normals.vcf.gz
bcftools index -t panel_of_normals.vcf.gz
