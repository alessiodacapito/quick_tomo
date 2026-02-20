#!/bin/bash

#add AreTomo binary location to PATH (or use full path below)
export PATH="$HOME:$PATH"

ARETOMO_BIN="$HOME/quick_tomo/AreTomo_1.3.4_Cuda118_Feb22_2023"

#spinner 
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local start_time=$(date +%s)

    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 3); do
            elapsed=$(( $(date +%s) - start_time ))
            printf "\r[%c] Running (%02d:%02d elapsed)" \
                "${spinstr:$i:1}" \
                $((elapsed / 60)) $((elapsed % 60))
            sleep "$delay"
        done
    done
    printf "\rFinished (%02d:%02d elapsed)\n" \
        $((elapsed / 60)) $((elapsed % 60))
}


echo "
######################################################################################################################################################
Welcome to QuickTomo 0.2.2! This is a beta please report any bug. If you would like to have new features please contact me at adacapito@ibs.fr
######################################################################################################################################################
"

#prompt user for Scipion project directory
read -rp "
Enter the full path to your Scipion project: " project_path

if [[ ! -d "$project_path" ]]; then
    echo "Error: Directory does not exist: $project_path"
    exit 1
fi

#prompt user for output directory
read -rp "
Enter the path to the output directory (where reconstructed tomograms will be saved): " output_dir

#prompt user for binning factor
read -rp "
Choose your binning factor (consider MotionCor binning): " bin_factor

#odd/even option
read -rp "
Do you want odd/even tomo reconstructions for denoising training? (y/n) " odd_even

#create output directory if needed
echo "
#################################################################################################################################
Starting the magic! this will take a while, if you are bored please drink water, you are probably more dehydrated than you think!
#################################################################################################################################
"
mkdir -p "$output_dir" || {
    echo "Error: Could not create or access output directory: $output_dir"
    exit 1
}


#create log out dir
log_dir="$output_dir/logs"
mkdir -p "$log_dir" || {
    echo "Error: Could not create log directory: $log_dir"
    exit 1
}

#Find all *_ProtImodCtfCorrection/extra/ directories
find "$project_path"/Runs/ -type d -name "*_ProtImodCtfCorrection" | while read -r prot_dir; do
    extra_dir="$prot_dir/extra"

    [[ -d "$extra_dir" ]] || continue

    echo "
    ################################
    Processing directory: $extra_dir
    ################################"

    find "$extra_dir" -mindepth 1 -maxdepth 1 -type d | while read -r ts_dir; do
        echo "  
	Processing tilt series in directory : $ts_dir"

        mrcs_file=$(find "$ts_dir" -maxdepth 1 -type f -name "*.mrcs" | head -n 1)
        tlt_file=$(find "$ts_dir" -maxdepth 1 -type f -name "*.tlt" | head -n 1)

        if [[ -z "$mrcs_file" || -z "$tlt_file" ]]; then
            echo "    Skipping: .mrcs or .tlt not found"
            continue
        fi

        base_name=$(basename "$mrcs_file" .mrcs)

        # ------------------
        # FULL TOMOGRAM
        # ------------------
        full_tmp="$ts_dir/${base_name}_tomoRecon_full.mrc"
        full_out="$output_dir/${base_name}_tomoRecon_full.mrc"

        echo "
        ############################
	Reconstructing full tomogram
	############################"
        
	full_log="$log_dir/${base_name}_ARETOMO_full.log"

        "$ARETOMO_BIN" \
            -inmrc "$mrcs_file" \
            -outmrc "$full_tmp" \
            -AngFile "$tlt_file" \
            -AlignZ 250 -VolZ 600 -OutBin "$bin_factor" \
            -Gpu 0 -FlipVol 1 -Wbp 1 -DarkTol 0 \
	    > "$full_log" 2>&1 &
	
	pid_full=$!
	spinner "$pid_full"
	wait "$pid_full"

        [[ -f "$full_tmp" ]] && mv "$full_tmp" "$full_out"

        # ------------------
        # ODD / EVEN TOMOGRAMS
        # ------------------
        if [[ "$odd_even" == "y" ]]; then
            echo "
	    ###################################
	    Reconstructing odd/even half tomos
	    ###################################"

            tmp_dir="$ts_dir/tmp_odd_even"
            mkdir -p "$tmp_dir"

            # split stack
	    e2proc2d.py --split 2 "$mrcs_file" "$tmp_dir/${base_name}.mrcs"
		
            odd_ts="$tmp_dir/${base_name}..00.mrcs"
            even_ts="$tmp_dir/${base_name}..01.mrcs"

            odd_tlt="$tmp_dir/${base_name}_odd.tlt"
            even_tlt="$tmp_dir/${base_name}_even.tlt"

            awk 'NR % 2 == 1' "$tlt_file" > "$odd_tlt"
            awk 'NR % 2 == 0' "$tlt_file" > "$even_tlt"

            even_tmp="$ts_dir/${base_name}_tomoRecon_even.mrc"
            even_out="$output_dir/${base_name}_tomoRecon_even.mrc"

            odd_tmp="$ts_dir/${base_name}_tomoRecon_odd.mrc"
            odd_out="$output_dir/${base_name}_tomoRecon_odd.mrc"

	    even_log="$log_dir/${base_name}_ARETOMO_even.log"
            odd_log="$log_dir/${base_name}_ARETOMO_odd.log"
            
	    "$ARETOMO_BIN" \
                -inmrc "$even_ts" \
                -outmrc "$even_tmp" \
                -AngFile "$even_tlt" \
                -AlignZ 250 -VolZ 600 -OutBin "$bin_factor" \
                -Gpu 0 -FlipVol 1 -Wbp 1 -DarkTol 0 \
		> "$even_log" 2>&1 &

pid_even=$!

            "$ARETOMO_BIN" \
                -inmrc "$odd_ts" \
                -outmrc "$odd_tmp" \
                -AngFile "$odd_tlt" \
                -AlignZ 250 -VolZ 600 -OutBin "$bin_factor" \
                -Gpu 1 -FlipVol 1 -Wbp 1 -DarkTol 0 \
		> "$odd_log" 2>&1 &

pid_odd=$!


spinner "$pid_even" &
spin_pid=$!
wait "$pid_even"
wait "$pid_odd"
kill "$spin_pid" 2>/dev/null


            [[ -f "$even_tmp" ]] && mv "$even_tmp" "$even_out"
            [[ -f "$odd_tmp" ]] && mv "$odd_tmp" "$odd_out"

            #cleanup
            rm -rf "$tmp_dir"
        fi
    done
done

echo "
#######################################
quick_tomo finished all reconstructions
#######################################
"
