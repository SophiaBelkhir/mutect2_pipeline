#!/bin/bash

bcftools concat -a -D *.vcf.gz | bcftools sort -Oz -o germline_resource.vcf.gz
bcftools index -t germline_resource.vcf.gz
