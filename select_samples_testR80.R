# Load required library
library(dplyr)

# Define input and output files
input_file <- "/home/clara.figueiredo/Projects/CZ1/sorted_by_reads.log"
output_file <- "/home/clara.figueiredo/Projects/CZ1/maptest.tsv"

# Ensure the output directory exists
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)

# Read the input file, skipping the header row
data <- read.delim(input_file, header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Step 1: Retain only the row with the highest Retained_Reads for each SAMPLE
deduplicated <- data %>%
  group_by(SAMPLE) %>%
  slice_max(order_by = Retained_Reads, n = 1) %>%
  ungroup()

# Step 2: Filter samples within the 10-15 million reads range
filtered <- deduplicated %>%
  filter(Retained_Reads >= 10000000 & Retained_Reads <= 15500000,
    POPULATION %in% c("CAR", "LIM", "GAR", "CHA", "POU"))

# Step 3: Split by population and select the top 4 samples with highest Retained_Reads
selected <- filtered %>%
  group_by(POPULATION) %>%
  slice_max(order_by = Retained_Reads, n = 4, with_ties = FALSE) %>%
  ungroup()

# Step 4: Create the final output file
final_output <- selected %>%
  transmute(SAMPLE, STATUS = "test")

write.table(
  final_output,
  file = output_file,
  sep = "\t",
  row.names = FALSE,
  col.names = FALSE,
  quote = FALSE
)

library(readr)
write_tsv(final_output, "/home/clara.figueiredo/Projects/CZ1/test_Mmn.map", col_names = FALSE)

