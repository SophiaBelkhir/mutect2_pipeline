#!/usr/bin/env bash
#
# Usage: ./download_and_build_samplesheet.sh [crams.tsv]
#
# 1) For each row in the input TSV (file_path, file_name, normal_or_tumour),
#    downloads the .cram + matching .crai from irods via iget, into /normals or /tumours.
# 2) Builds samplesheet_<date>.csv with columns:
#       sample_prefix, tumour_cram, normal_cram (but no header line)
#    where sample_prefix is the numeric part of file_name before the first
#    "T" or "H", and only one of the last two columns is filled per row.
# N.B: requires initialization of irods environment (e.g. `iinit`) before running.

set -euo pipefail

tsv="${1:-crams.tsv}"

if [[ ! -f "$tsv" ]]; then
    echo "Error: input file '$tsv' not found." >&2
    exit 1
fi

stamp=$(date +%Y%m%d)
samplesheet="samplesheet_${stamp}.csv"

# Avoiding appending to an existing file
if [[ -f "$samplesheet" ]]; then
    echo "Error: samplesheet '$samplesheet' already exists. Please remove or rename it before running this script." >&2
    exit 1
fi

normals_dir="normals"
tumours_dir="tumours"

mkdir -p "$normals_dir" "$tumours_dir"

# skip header line of the tsv, then process each row
tail -n +2 "$tsv" | while IFS=$'\t' read -r file_path file_name group; do
    # strip any stray carriage returns 
    file_path="${file_path%$'\r'}"
    file_name="${file_name%$'\r'}.cram"
    group="${group%$'\r'}"

    [[ -z "$file_path" ]] && continue

    if [[ "$group" == "tumours" ]]; then
        destdir="$tumours_dir"
    else
        destdir="$normals_dir"
    fi

    # Check that the file doesn't already exist in the destination directory
    if [[ ! -f "$destdir/$file_name" ]]; then
        echo "Downloading $file_path -> $destdir/"
        iget -K -P "$file_path" "$destdir/"
        iget -K -P "${file_path}.crai" "$destdir/"
    else
        echo "File $destdir/$file_name already exists. Skipping download."
    fi

    # sample prefix = numeric part of file_name before first T or H
    prefix=$(echo "$file_name" | sed -E 's/[TH].*//')

    if [[ "$group" == "tumours" ]]; then
        echo "${prefix},${file_name}," >> "$samplesheet"
    else
        echo "${prefix},,${file_name}" >> "$samplesheet"
    fi
done

# Make sure each row is unique by sorting and removing duplicates
sort -u "$samplesheet" -o "$samplesheet"

echo "Done. Samplesheet written to $samplesheet"