#!/bin/bash

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scan_failed_bcftools_mpileup_tasks.sh [work_dir]

Scan a Nextflow work directory for failed callBcftoolsMpileupVariants tasks with exit code 255.
Reports the work directory, exit code, interval, sample, and output name.
EOF
}

root_dir=${1:-work}

if [ "${root_dir}" = "-h" ] || [ "${root_dir}" = "--help" ]; then
    usage
    exit 0
fi

if [ ! -d "${root_dir}" ]; then
    echo "Error: work directory '${root_dir}' does not exist." >&2
    exit 1
fi

case "${root_dir}" in
    /*) ;;
    *) root_dir=$(cd "${root_dir}" && pwd) ;;
esac

printf 'workdir\texitcode\tinterval\tsample\toutput\n'

find "${root_dir}" -type f -name .command.sh -print0 |
while IFS= read -r -d '' command_script; do
    task_dir=$(dirname "${command_script}")
    exitcode_file="${task_dir}/.exitcode"

    [ -f "${exitcode_file}" ] || continue
    [ -f "${command_script}" ] || continue

    # Only report the bcftools mpileup process.
    if ! grep -q 'bcftools mpileup' "${command_script}"; then
        continue
    fi
    if ! grep -q '\.bcftools\.mpileup\.vcf\.gz' "${command_script}"; then
        continue
    fi

    exitcode=$(tr -d '[:space:]' < "${exitcode_file}")
    [ "${exitcode}" = "255" ] || continue

    output_name=$(grep -oE '[^[:space:]]+\.bcftools\.mpileup\.vcf\.gz' "${command_script}" | head -n 1 || true)
    interval=''
    sample=''
    if [[ "${output_name}" =~ ^([^.]+)\.(.+)\.bcftools\.mpileup\.vcf\.gz$ ]]; then
        interval=${BASH_REMATCH[1]}
        sample=${BASH_REMATCH[2]}
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' "${task_dir}" "${exitcode}" "${interval}" "${sample}" "${output_name}"
done