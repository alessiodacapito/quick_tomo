#!/bin/bash

# Add AreTomo binary location to PATH (or use full path below)
export PATH="$HOME:$PATH"

# Prompt user for Scipion project directory
read -rp "Enter the full path to your Scipion project directory: " project_path

# Validate input
if [[ ! -d "$project_path" ]]; then
    echo "Error: Directory does not exist: $project_path"
    exit 1
fi

# Prompt user for output directory
read -rp "Enter the path to the output directory (where reconstructed tomograms will be saved): " output_dir

# Create output directory if it doesn't exist
mkdir -p "$output_dir" || {
    echo "Error: Could not create or access output directory: $output_dir"
    exit 1
}

# Find all *_ProtImodCtfCorrection/extra/ directories
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

        # Build output filenames
        base_name=$(basename "$mrcs_file" .mrcs)
        temp_output="$ts_dir/${base_name}_tomoRecon.mrc"
        final_output="$output_dir/${base_name}_tomoRecon.mrc"

        echo "    Running AreTomo on:"
        echo "      Input MRCS: $mrcs_file"
        echo "      Angle File: $tlt_file"
        echo "      Temp Output: $temp_output"
        echo "      Final Output: $final_output"

        # Run AreTomo
        "$HOME/quick_tomo/AreTomo_1.3.4_Cuda118_Feb22_2023" \
          -inmrc "$mrcs_file" \
          -outmrc "$temp_output" \
          -AngFile "$tlt_file" \
          -AlignZ 250 -VolZ 1400 -OutBin 4 \
          -Gpu 0,1,2,3 -FlipVol 1 -Wbp 1 -DarkTol 0

        # Move result to output directory
        if [[ -f "$temp_output" ]]; then
            mv "$temp_output" "$final_output"
            echo "    Saved to: $final_output"
        else
            echo "    Error: AreTomo output not found: $temp_output"
        fi
    done
done

echo "All tilt series processed."
