#METAINFO - construction of barcode files and popmap file
library(readxl)   # For reading Excel files
library(dplyr)    # For data manipulation
library(stringr)  # For string manipulation
setwd("/home/clara.figueiredo/Projects/CZ1")

## Complete sample inventory ##
inventory <- readxl::read_xlsx('/home/clara.figueiredo/Projects/CZ1/CZ1_sample_inventory.xlsx', 'Inventory', col_names = TRUE) 
str(inventory)  # Display the structure of the inventory data
head(inventory) # Display the first few rows of the inventory data

#INFO
## Sampling
unique_locations <- unique(inventory$Location)  # Extract unique locations
biopsy_counts <- table(inventory$Location[!is.na(inventory$Biopsy)])  # Count the number of biopsies per location

# Create a data frame combining unique locations and their biopsy counts
SAMPLING <- data.frame(Location = unique_locations) 
SAMPLING$BiopsyCount <- biopsy_counts[match(SAMPLING$Location, names(biopsy_counts))]

# Replace NA with 0 in BiopsyCount for locations with no biopsies
SAMPLING$BiopsyCount[is.na(SAMPLING$BiopsyCount)] <- 0

# Display the SAMPLING data frame
print(SAMPLING)

# List of indices and corresponding barcodes
indices <- read.csv('/home/clara.figueiredo/Projects/CZ1/indices_table.csv')  

# Complete sequence submission
ssal0124 <- readxl::read_xlsx('/home/clara.figueiredo/Projects/CZ1/index_map.xlsx', 'Ssal2024')

# Remove biopsy tag (T_) from sample names
inventory$Biopsy <- stringr::str_replace(
  inventory$Biopsy,  # Name of biopsy samples
  "T_", ""          # String to replace
)

# Remove biopsy and replicate tags from submission for temporary sample code
ssal0124$code <- stringr::str_replace_all(
  ssal0124$SampleName,  # Names of submitted samples
  c("T_" = "", "T-" = "",  # Tissue tags
    "_IR" = "", "_ER" = "")  # Replicate tags
)

#change col name of pop code
inventory <- inventory %>%
  rename(Pop_code = `Pop code`)

# Merge metadata with sequence submission
merge(
  x = ssal0124[, c(3:6, 7, 9, 12, 19)], by.x = "code",
  y = inventory[, 1:12], by.y = "Biopsy",
  all.x = TRUE
) -> seqsub

# Remove temporary sample codes
seqsub <- seqsub[, !colnames(seqsub) %in% c('code', "Code")]

# Number of samples sequenced by site
table(seqsub$Location)


##### BARCODES #####
#External Indices - Files are saved in FastQ format, separated by the external indices (i5/i7). 
#Each of these files corresponds to a "Pool" of samples that share a common external index but have variable internal indices.

# dir.raw.fq <- "data/raw/" #Local directory setting
dir.raw.fq <- "/home/clara.figueiredo/Projects/CZ1/Raw"

# list of sequence directories
fq <- list() #empty list
list.files(path = dir.raw.fq, 
           pattern = "_",  # populates it with the names of files (or directories) in dir.raw.fq that contain an underscore
           include.dirs = T) -> fq

#Internal Indices
#To correctly assign reads to the samples, we will need to generate a barcode index file for each pool. 
#This file contains the barcode sequence for the forward (P1) and reverse (P2) adapters as well as the sample name.

# list names of index pools
pools <- unique(seqsub$`Library Name`) 

# save each pool to a list - Create a List for Each Pool:
ls.pools <- list()
for (i in seq_along(pools)) { # for each pool
  cbind.data.frame( # join
    seqsub[seqsub$`Library Name` == pools[i],]$SampleName, # sample
    seqsub[seqsub$`Library Name` == pools[i],]$`PstI Adaptor`, # p1 index
    seqsub[seqsub$`Library Name` == pools[i],]$`AclI Adaptor` # p2 index
  ) -> x
  colnames(x) <- c("sample","p1","p2") # simplify column names
  # match the index name to the barcode sequence
  match(x$p1,indices$index) -> n # p1 sequence 
  match(x$p2,indices$index) -> m # p2 sequence 
  cbind.data.frame( # join
    indices$sequence[n], # p1 sequence
    indices$sequence[m], # p2 sequence
    seqsub[seqsub$`Library Name` == pools[i],]$SampleName # sample
  ) -> ls.pools[[i]]
  colnames(ls.pools[[i]]) <- c("p1","p2","sample") # simplify column names
}
pools <- names(ls.pools) # simplify pool names
# write a barcode file for each pool
barcode.dir <- "./barcode/"
unlink(barcode.dir)
dir.create(barcode.dir)
for (i in seq_along(ls.pools)) {
  write.table(
    ls.pools[[i]],
    paste0(barcode.dir,
           gsub("[^[:alnum:]]","",names(ls.pools)[i]),
           ".barcode"),
    sep = "\t",  # separate with tab
    quote = F , # exclude quotes
    row.names = F,col.names = F # exclude row and column names
  )
}
# collect list of barcode files
barcodes <- list.files(path = "./barcode", pattern = ".barcode", recursive = T,full.names = T)

# Leer muestras de los archivos de c??digo de barras
barcode_samples <- c()
for (file in barcodes) {
  df <- read.table(file, sep = "\t", header = FALSE, stringsAsFactors = FALSE)
  barcode_samples <- c(barcode_samples, df$V3)
}
barcode_samples <- unique(barcode_samples)

###########
# POP MAP #
###########

# Normalizar nombres de muestras en el inventario y en los barcode files
inventory$Biopsy <- as.character(inventory$Biopsy)  # Asegurar tipo character
inventory$Biopsy <- str_trim(inventory$Biopsy)      # Eliminar espacios adicionales
inventory$Biopsy <- str_replace_all(inventory$Biopsy, c("^T_" = "", "^T-" = ""))
inventory$Pop_code <- str_trim(as.character(inventory$Pop_code))
barcode_samples <- str_trim(barcode_samples)

# Eliminar NAs de Biopsy
inventory <- inventory %>% filter(!is.na(Biopsy))

# Crear el popmap con solo las muestras originales presentes en el inventario y en los barcode files
popmap <- inventory %>%
  rename(SampleName = Biopsy) %>%
  filter(SampleName %in% barcode_samples & !grepl("_(IR|ER)$", SampleName)) %>%
  select(SampleName, Pop_code)

# Filtrar r??plicas que tienen equivalentes en el inventario
replicate_samples <- barcode_samples[grepl("_(IR|ER)$", barcode_samples)]
replicate_df <- data.frame(SampleName = replicate_samples)
replicate_df <- replicate_df %>%
  mutate(OriginalSample = str_trim(str_replace(SampleName, "_(IR|ER)$", ""))) %>%
  filter(OriginalSample %in% inventory$Biopsy)  # Filtrar solo r??plicas v??lidas

print("OriginalSample values:")
print(unique(replicate_df$OriginalSample))
print("Biopsy values in inventory:")
print(unique(inventory$Biopsy))

unmatched <- replicate_df$OriginalSample[!(replicate_df$OriginalSample %in% inventory$Biopsy)]
print("Unmatched OriginalSamples:")
print(unmatched)

# Depuraci??n de asignaciones de Pop_code
replicate_df <- replicate_df %>%
  rowwise() %>%
  mutate(Pop_code = {
    # Mostrar depuraci??n
    print(paste("Processing OriginalSample:", OriginalSample))
    print(paste("Checking for matches in Biopsy:"))
    matches <- inventory$Biopsy[inventory$Biopsy == OriginalSample]
    print(matches)
    pop_code <- inventory$Pop_code[inventory$Biopsy == OriginalSample]
    if (length(pop_code) > 0 && !is.na(pop_code[1])) {
      print(paste("Found Pop_code:", pop_code[1], "for", OriginalSample))
      as.character(pop_code[1])
    } else {
      print(paste("No Pop_code found for:", OriginalSample))
      "Unknown"
    }
  }) %>%
  ungroup() %>%
  select(SampleName, Pop_code)

# Verificar duplicados en el inventario
duplicated_biopsies <- inventory$Biopsy[duplicated(inventory$Biopsy)]
if (length(duplicated_biopsies) > 0) {
  print("Duplicated Biopsies in inventory:")
  print(duplicated_biopsies)
}

# Combinar el popmap con las r??plicas v??lidas
popmap <- bind_rows(popmap, replicate_df)


# Guardar el popmap
write.table(popmap, "popmap.wrk", col.names = FALSE, row.names = FALSE, quote = FALSE, sep = "\t")
