#!/bin/bash

# Prompt user for the base Scipion project directory
read -rp "Enter the full path to your Scipion project directory: " project_path

# Check if directory exists
if [[ ! -d "$project_path" ]]; then
    echo "Error: Directory does not exist: $project_path"
    exit 1
fi

# Find all *_ProtImodCtfCorrection/extra/ subdirectories
find "$project_path"/Runs/ -type d -name "*_ProtImodCtfCorrection" | while read -r prot_dir; do
    extra_dir="$prot_dir/extra"
    if [[ ! -d "$extra_dir" ]]; then
        echo "Skipping: no 'extra/' directory in $prot_dir"
        continue
    fi

    echo "Processing directory: $extra_dir"

    # Loop over each tilt series subdirectory inside extra/
    find "$extra_dir" -mindepth 1 -maxdepth 1 -type d | while read -r ts_dir; do
        echo "  Found tilt series directory: $ts_dir"

        # Look for one .mrcs file and one .tlt file
        mrcs_file=$(find "$ts_dir" -maxdepth 1 -type f -name "*.mrcs" | head -n 1)
        tlt_file=$(find "$ts_dir" -maxdepth 1 -type f -name "*.tlt" | head -n 1)

        if [[ -z "$mrcs_file" || -z "$tlt_file" ]]; then
            echo "    Skipping: .mrcs or .tlt file not found in $ts_dir"
            continue
        fi

        # Build output filename
        base_name=$(basename "$mrcs_file" .mrcs)
        output_file="$ts_dir/${base_name}_tomoRecon.mrc"

        echo "    Running AreTomo on:"
        echo "      Input MRCS: $mrcs_file"
        echo "      Angle File: $tlt_file"
        echo "      Output:     $output_file"

        # Run AreTomo command
        "$HOME/quick_tomo/AreTomo_1.3.4_Cuda118_Feb22_2023" \
          -inmrc "$mrcs_file" \
          -outmrc "$output_file" \
          -AngFile "$tlt_file" \
          -AlignZ 250 -VolZ 1400 -OutBin 4 \
          -Gpu 0,1,2,3 -FlipVol 1 -Wbp 1 -DarkTol 0

        echo "    Done."
    done
done

echo "All tilt series processed."
