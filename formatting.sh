#!/bin/bash

# Paths
RADTAG_DIR="/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/"
LOG_FILE="${RADTAG_DIR}demultiplexing_summary.log"
INVENTORY_FILE="/home/clara.figueiredo/Projects/CZ1/CZ1_sample_inventory.xlsx"
OUTPUT_FILE_POPULATION="/home/clara.figueiredo/Projects/CZ1/sorted_by_population.log"
OUTPUT_FILE_READS="/home/clara.figueiredo/Projects/CZ1/sorted_by_reads.log"
TEMP_CSV="/tmp/inventory.csv"
TEMP_FILTERED="/tmp/filtered_inventory.csv"
TEMP_CLEANED="/tmp/cleaned_log.tsv"

# Extract Filename and Retained Reads from process_radtags log files
echo "Extracting Filename and Retained Reads from log files..."
awk 'BEGIN {OFS="\t"} /^BEGIN per_barcode_raw_read_counts/, /^END/ {
    if ($1 ~ /^[ACGT]/) print $2, $6  # Extract Filename and Retained Reads
}' "${RADTAG_DIR}"process_radtags.*CZ*.log > "$TEMP_CLEANED"

# Convert Excel inventory to CSV
echo "Converting Excel inventory to CSV..."
source /opt/miniconda3/etc/profile.d/conda.sh
conda activate xls2csv_env
python3 <<EOF
import pandas as pd
input_file = "$INVENTORY_FILE"
output_file = "$TEMP_CSV"
df = pd.read_excel(input_file)
df.to_csv(output_file, index=False)
EOF

if [ $? -ne 0 ]; then
  echo "Error: Failed to convert Excel file to CSV."
  exit 1
fi

# Extract Biopsy and Pop code columns
echo "Filtering inventory for Biopsy and Pop code columns..."
awk -F',' 'NR==1 {
    for (i=1; i<=NF; i++) {
        if ($i == "Biopsy") bcol=i
        if ($i == "Pop code") pcol=i
    }
} NR > 1 {
    print $bcol","$pcol
}' "$TEMP_CSV" > "$TEMP_FILTERED"

# Merge log data with inventory, ensuring only matching samples are used
echo "Merging log and inventory data..."
awk -F'\t' 'BEGIN {
    # Load inventory into a hash map
    while ((getline < "'"$TEMP_FILTERED"'") > 0) {
        split($0, arr, ",")
        inventory[arr[1]] = arr[2]
    }
    print "SAMPLE\tRetained_Reads\tPOPULATION"
} {
    # Output only samples present in both files
    if (NR > 1 && $1 != "" && inventory[$1] != "") {
        print $1 "\t" $2 "\t" inventory[$1]
    }
}' "$TEMP_CLEANED" > "$LOG_FILE"

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -f "$TEMP_CSV" "$TEMP_FILTERED" "$TEMP_CLEANED"

# Sort by Population (alphabetical) and then by Retained Reads (descending)
echo "Sorting by Population and Retained Reads..."
sort -t $'\t' -k3,3 -k2,2nr "$LOG_FILE" -o "$OUTPUT_FILE_POPULATION"

# Sort only by Retained Reads (descending)
echo "Sorting by Retained Reads..."
sort -t $'\t' -k2,2nr "$LOG_FILE" -o "$OUTPUT_FILE_READS"

echo "Sorting complete. Outputs saved to $OUTPUT_FILE_POPULATION and $OUTPUT_FILE_READS."
