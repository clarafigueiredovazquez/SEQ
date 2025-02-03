#!/bin/bash
source /opt/miniconda3/etc/profile.d/conda.sh
conda activate stacks_env

# Debugging: Check if process_radtags is accessible
which process_radtags
if ! command -v process_radtags &> /dev/null; then
    echo "Error: process_radtags command not found."
    exit 1
fi

radtag_dir=/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/ # output directory for demultiplexed files
bcode=/home/clara.figueiredo/Projects/CZ1/barcode/
rawdir=/home/clara.figueiredo/Projects/CZ1/Raw/

# Create directories if they do not exist
mkdir -p "$radtag_dir"

# List of sequence directories 
# List of sequence directories (excluding any Undetermined)
fq=($(ls "${rawdir}" | grep "CZ" | sort))
# P1 reads (forward)
p1=($(find "${rawdir}" -type f -name "*_1.fq.gz" | sort))

# P2 reads (reverse)
p2=($(find "${rawdir}" -type f -name "*_2.fq.gz" | sort))

# Ensure P1 and P2 have the same number of files
if [ ${#p1[@]} -ne ${#p2[@]} ]; then
  echo "Error: Mismatch between number of P1 and P2 files!"
  exit 1
fi

# Echo the gathered files for verification
echo "Found the following input files:"
echo "Sequence directories: ${fq[@]}"
echo "P1 reads: ${p1[@]}"
echo "P2 reads: ${p2[@]}"

# Check the barcode files
barcodes=($(ls "${bcode}" | grep ".barcode"))
echo "Number of P1 reads: ${#p1[@]}"
echo "Number of P2 reads: ${#p2[@]}"

# Ensure that the number of barcodes matches the number of P1/P2 pairs
if [ ${#barcodes[@]} -ne ${#p1[@]} ]; then
  echo "Error: Mismatch between number of barcode files and P1/P2 reads!"
  echo "Barcodes found: ${barcodes[@]}"
  exit 1
fi

# Debugging output to ensure correct alignment
echo "Debugging outputs:"
for i in "${!p1[@]}"; do
   echo "Sample ${i}:"
   echo "  P1: ${p1[i]}"
   echo "  P2: ${p2[i]}"
   echo "  Barcode: ${bcode}/${barcodes[i]}"
done

 #run demultiplexing ###This does not produce one cumulative log !!!!!
    for i in "${!p1[@]}"; 
    do
  # Check if a corresponding barcode exists
   barcode_path="${bcode}/${barcodes[i]}"

   echo "Processing sample ${i}:"
   echo "  P1: ${p1[i]}"
   echo "  P2: ${p2[i]}"
   echo "  Barcode: ${barcode_path}"
   radtag_dir=/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/"$l" 
   process_radtags -1 "${p1[i]}" -2 "${p2[i]}" -b "${barcode_path}" --paired -o $radtag_dir --threads 4 -c -q -r --inline_inline --renz_1 pstI --renz_2 aclI
   done 


#other option to produce one .log summarizing all the information .log - If you want to generate a single log file summarizing all runs, modify the loop as follows:
LOGFILE="/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/demultiplexing_summary.log"

# Clear log file before starting (optional)
"$LOGFILE"

for i in "${!p1[@]}"; 
do
    barcode_path="${bcode}/${barcodes[i]}"
    radtag_dir="/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/${fq[i]}"

    echo "Processing sample ${i}:" | tee -a "$LOGFILE"
    echo "  P1: ${p1[i]}" | tee -a "$LOGFILE"
    echo "  P2: ${p2[i]}" | tee -a "$LOGFILE"
    echo "  Barcode: ${barcode_path}" | tee -a "$LOGFILE"

    process_radtags -1 "${p1[i]}" -2 "${p2[i]}" -b "${barcode_path}" --paired -o "$radtag_dir" --threads 4 -c -q -r --inline_inline --renz_1 pstI --renz_2 aclI &>> "$LOGFILE"
    
    echo "Finished processing sample ${i}" | tee -a "$LOGFILE"
    echo "-----------------------------" | tee -a "$LOGFILE"
done
