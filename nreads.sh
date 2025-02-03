#!/bin/bash
#nreads.sh
radtag_dir=/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/ # output directory for demultiplexed files
bcode=/home/clara.figueiredo/Projects/CZ1/barcode/ # Barcode directory (barcode file used for demultiplexing)
rawdir=/home/clara.figueiredo/Projects/CZ1/Raw/ # Directory containing raw sequencing files
curdir=$(pwd)  # Stores the current directory path
dmpxlog="${radtag_dir}demultiplexing_summary_3.log" # Log file path for storing demultiplexing summary

# Create the log file if it doesn't exist
touch "$dmpxlog"

#generate summary of demultiplexing
cat "${radtag_dir}"process_radtags.*CZ*.log | awk '/^Barcode\tFilename/' > $dmpxlog

cd $radtag_dir 
list=$(ls *GVA* | cut -f1 -d'.' | sort | uniq)
for p in $list
    do
    fn="$p".1.fq.gz
    zcat "$p".[12].fq.gz "$p".rem*.fq.gz | awk -v p=$p 'BEGIN{OFS="\t"} END{print "NA", p, "NA", "NA", "NA", NR/4}' >> "$dmpxlog"
    done
cd $curdir

echo "Matching files:"
ls ${radtag_dir}process_radtags.*CZ*.log

cat ${radtag_dir}process_radtags.*CZ*.log | awk 'BEGIN{FS=OFS="\t"} /^Barcode\tFilename/, /^END/ {if (/^[ACGT]/) print $1, $2, $3, $4, $5, $6}' >> "$dmpxlog"

# Paths
LOG_FILE="/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/demultiplexing_summary.log"
INVENTORY_FILE="/home/clara.figueiredo/Projects/CZ1/CZ1_sample_inventory.xlsx"
OUTPUT_FILE="/home/clara.figueiredo/Projects/CZ1/updated_demultiplexing_summary.log"
TEMP_CSV="/tmp/inventory.csv"

# Activate the xls2csv_env environment
source /opt/miniconda3/etc/profile.d/conda.sh
conda activate xls2csv_env

echo "Converting Excel file to CSV using Python..."
python3 /home/clara.figueiredo/Projects/CZ1/dmpx_fastq/convert_excel_to_csv.py || {
    echo "Error: Failed to convert Excel file to CSV using Python."
    exit 1
}

# Step 2: Extract relevant columns (Biopsy and Pop code) from the CSV file
echo "Extracting relevant columns from inventory"

head "$TEMP_CSV"

awk -F',' 'NR==1 {
    for (i=1; i<=NF; i++) {
        if ($i == "Biopsy") bcol=i;
        if ($i == "Pop code") pcol=i;
    }
    print "Biopsy column index:", bcol;
    print "Pop code column index:", pcol;
} NR > 1 {
    print $bcol","$pcol
}' "$TEMP_CSV"

awk -F',' 'NR==1 {for (i=1; i<=NF; i++) if ($i == "Biopsy") bcol=i; if ($i == "Pop code") pcol=i} NR>1 {print $bcol","$pcol}' "$TEMP_CSV" > /tmp/filtered_inventory.csv

# Step 3: Prepare the log file for merging
echo "Cleaning up the log file"
awk 'NR > 1 && $2 != "" {print $2 "\t" $6}' "$LOG_FILE" > /tmp/cleaned_log.tsv

# Step 4: Merge the log data with inventory data
echo "Merging log file with population data"
awk -F'\t' 'BEGIN {
    while ((getline < "/tmp/filtered_inventory.csv") > 0) {
        split($0, arr, ",")
        inventory[arr[1]] = arr[2]
    }
} {
    if (NR == 1) {
        print $0 "\tPopulation"
    } else {
        pop = inventory[$1]
        if (pop == "") pop = "NA"
        print $0 "\t" pop
    }
}' /tmp/cleaned_log.tsv > "$OUTPUT_FILE"

# Step 5: Clean up temporary files
echo "Cleaning up temporary files..."
rm -f /tmp/inventory.csv /tmp/filtered_inventory.csv /tmp/cleaned_log.tsv

echo "Process completed. Merged file saved to $OUTPUT_FILE."