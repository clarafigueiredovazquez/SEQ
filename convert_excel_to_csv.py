import pandas as pd

# Define input and output paths
input_file = "/home/clara.figueiredo/Projects/CZ1/CZ1_sample_inventory.xlsx"
output_file = "/tmp/inventory.csv"

try:
    # Read the Excel file and write the required columns to CSV
    df = pd.read_excel(input_file, sheet_name="Inventory")
    df.to_csv(output_file, index=False)
    print(f"Converted {input_file} to {output_file}")
except Exception as e:
    print(f"Error during Excel to CSV conversion: {e}")
