#!/bin/bash
#create a barcode file

#Define the directory containing barcode files
barcode_dir="barcode"  # Adjust this path if needed
output_file="combined_barcodes_CZ1.txt"  # Name of the output file

# Create or overwrite the output file
> $output_file

# Append the content of files with "CZ1" in their names
for file in "$barcode_dir"/*CZ1*.barcode; do
    cat "$file" >> $output_file
done

# Append the content of "PRTPool07.barcode"
if [[ -f "$barcode_dir/PRTPool07.barcode" ]]; then
    cat "$barcode_dir/PRTPool07.barcode" >> $output_file
else
    echo "File PRTPool07.barcode not found in $barcode_dir"
fi

# Print completion message
echo "Combined barcode file created: $output_file"