#!/bin/bash

##############################################################################
# Script to consolidate batch subdirectories into a single directory structure
# Usage: ./consolidate_batches.sh [--dry-run|-n] SOURCE_PATH DESTINATION_PATH DIRECTORY_NAMES...
# Example: ./consolidate_batches.sh /nfs/dog_n_devil/sb71/mutect_stage1_outputs \
#          /lustre/scratch126/casm/staging/team267_murchison/sb71/devils_high_cov/02_04_26_stage1_outputs_staging \
#          batch_01 batch_02 batch_05 subset_A sample_001
##############################################################################

set -euo pipefail

# Configuration
DRY_RUN=false

if [[ "${1:-}" == "-n" || "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    shift
fi

SOURCE_PATH="${1:?Error: SOURCE_PATH not provided}"
DEST_PATH="${2:?Error: DESTINATION_PATH not provided}"
shift 2

# Directories to process (exact names as they appear in source)
DIRECTORIES=("$@")

if [[ ${#DIRECTORIES[@]} -eq 0 ]]; then
    echo "Error: No batch numbers specified"
    echo "Usage: $0 SOURCE_PATH DEST_PATH DIRECTORY_NAME1 DIRECTORY_NAME2 ..."
    exit 1
fi

RSYNC_OPTS=(-avh --progress --partial)
if [[ "$DRY_RUN" == true ]]; then
    RSYNC_OPTS+=(--dry-run)
fi

# Target subdirectories (these should exist in each batch directory)
TARGET_DIRS=(
    "InitialNormalHaplotypeCallerCalls"
    "InitialNormalMutectCalls"
    "InitialTumourMutectCalls"
)

# Validate source path
if [[ ! -d "$SOURCE_PATH" ]]; then
    echo "Error: Source path does not exist: $SOURCE_PATH"
    exit 1
fi

# Create destination directory if it doesn't exist
if [[ ! -d "$DEST_PATH" ]]; then
    echo "Creating destination directory: $DEST_PATH"
    mkdir -p "$DEST_PATH"
fi

# Create the three consolidation directories
echo "Creating target directories in $DEST_PATH..."
for target_dir in "${TARGET_DIRS[@]}"; do
    mkdir -p "$DEST_PATH/$target_dir"
    echo "  ✓ $target_dir"
done

# Process each batch
echo ""
echo "Processing batches..."
if [[ "$DRY_RUN" == true ]]; then
    echo "Dry run enabled: no files will be copied"
fi
for dir_name in "${DIRECTORIES[@]}"; do
    batch_dir="$SOURCE_PATH/$dir_name"
    
    if [[ ! -d "$batch_dir" ]]; then
        echo "  ⚠ Warning: Directory not found at $batch_dir"
        continue
    fi
    
    echo "  Processing $dir_name..."
    
    # Copy files from each target directory
    for target_dir in "${TARGET_DIRS[@]}"; do
        source_subdir="$batch_dir/$target_dir"
        dest_subdir="$DEST_PATH/$target_dir"
        
        if [[ ! -d "$source_subdir" ]]; then
            echo "    ⚠ Subdirectory not found: $target_dir"
            continue
        fi
        
        # Count files to copy
        file_count=$(find "$source_subdir" -maxdepth 1 -type f | wc -l)
        
        if [[ $file_count -gt 0 ]]; then
            echo "    Copying $file_count files from $target_dir..."
            rsync "${RSYNC_OPTS[@]}" "$source_subdir/" "$dest_subdir/"
        fi
    done
done

echo ""
echo "============================================"
echo "Consolidation complete!"
echo "============================================"
if [[ "$DRY_RUN" == true ]]; then
    echo "Mode: dry-run"
fi
echo "Destination: $DEST_PATH"
echo ""
echo "Directory summary:"
for target_dir in "${TARGET_DIRS[@]}"; do
    file_count=$(find "$DEST_PATH/$target_dir" -maxdepth 1 -type f 2>/dev/null | wc -l)
    echo "  $target_dir: $file_count files"
done
