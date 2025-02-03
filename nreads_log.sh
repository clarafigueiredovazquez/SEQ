#!/bin/bash
#nreads_log.sh
radtag_dir="/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/" # Directory for demultiplexed files
bcode="/home/clara.figueiredo/Projects/CZ1/barcode/" # Barcode directory
rawdir="/home/clara.figueiredo/Projects/CZ1/Raw/" # Raw sequencing files directory
curdir=$(pwd) # Store current working directory
dmpxlog="${radtag_dir}demultiplexing_summary_3.log" # Log file for demultiplexing summary

# Ensure the log file exists
touch "$dmpxlog"

# Step 1: Extract Sample ID and Retained Reads from process_radtags log files
echo "Processing radtags log files..."
echo -e "Sample_ID\tRetained_Reads" > "$dmpxlog"
cat ${radtag_dir}process_radtags.*CZ*.log | awk 'BEGIN{FS=OFS="\t"} /^Barcode\tFilename/, /^END/ {if (/^[ACGT]/) print $2, $6}' >> "$dmpxlog"

# Paths
LOG_FILE="$dmpxlog"
INVENTORY_FILE="/home/clara.figueiredo/Projects/CZ1/CZ1_sample_inventory.xlsx"
OUTPUT_FILE="/home/clara.figueiredo/Projects/CZ1/updated_demultiplexing_summary.log"
TEMP_CSV="/tmp/inventory.csv"

# Step 2: Convert Excel file to CSV
echo "Converting Excel file to CSV using Python..."
source /opt/miniconda3/etc/profile.d/conda.sh
conda activate xls2csv_env

python3 /home/clara.figueiredo/Projects/CZ1/dmpx_fastq/convert_excel_to_csv.py || {
    echo "Error: Failed to convert Excel file to CSV using Python."
    exit 1
}

# Step 3: Extract Sample ID (Biopsy) and Population Code (Pop code) from inventory
echo "Extracting relevant columns from inventory..."
awk -F',' 'NR==1 {
    for (i=1; i<=NF; i++) {
        if ($i == "Biopsy") bcol=i;
        if ($i == "Pop code") pcol=i;
    }
} NR > 1 {
    print $bcol","$pcol
}' "$TEMP_CSV" > /tmp/filtered_inventory.csv

# Step 4: Prepare the log file for merging (Ensure tab-separated format)
echo "Cleaning up the log file..."
awk 'NR > 1 && $1 != "" {print $1 "\t" $2}' "$LOG_FILE" > /tmp/cleaned_log.tsv

# Step 5: Merge Sample ID, Retained Reads, and Population Code
echo "Merging log file with population data..."
awk -F'\t' 'BEGIN {
    while ((getline < "/tmp/filtered_inventory.csv") > 0) {
        split($0, arr, ",")
        gsub(/_IR|_ER/, "", arr[1]) # Remove replicate suffix for matching
        inventory[arr[1]] = arr[2]
    }
} {
    if (NR == 1) {
        print "Sample_ID\tRetained_Reads\tPopulation" # Output header
    } else {
        sample_id = $1
        core_id = sample_id
        gsub(/_IR|_ER/, "", core_id) # Remove _IR/_ER for matching

        pop = inventory[core_id]
        if (pop == "") pop = "NA"

        print sample_id, $2, pop
    }
}' OFS='\t' /tmp/cleaned_log.tsv > "$OUTPUT_FILE"

# Step 6: Clean up temporary files
echo "Cleaning up temporary files..."
rm -f /tmp/inventory.csv /tmp/filtered_inventory.csv /tmp/cleaned_log.tsv

echo "Process completed. Merged file saved to $OUTPUT_FILE."
