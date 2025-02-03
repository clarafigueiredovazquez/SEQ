# Load required libraries
library(readr)
library(dplyr)
library(knitr)
library(ggplot2)
# Define column names manually
column_names <- c("M", "n", "m", "Locus_ID", "SNP_ID", "Sample_Size", "Hobs", "Hexp", "Fis", "HWE_P")

# Read the gzipped TSV file with column names
t <- read_tsv("/home/clara.figueiredo/Projects/CZ1/Mmn_test_stats_additional_Mmn.txt.gz", 
              col_names = column_names)

# Group by M, n, m, and Locus_ID, then calculate summary statistics
loc <- t %>% group_by(M, n, m, Locus_ID) %>% summarise(SNP = n(),
                                                       Hex = sum(Fis < 0 & HWE_P < 0.05),
                                                       Hdef = sum(Fis > 0 & HWE_P < 0.05))
test_sum <- loc %>% group_by(M, n, m) %>% 
  summarise(Nloci = n(),
            NSNP = sum(SNP),
            fr_Het_Excess = round(sum(Hex > 0)/Nloci,4),
            fr_Het_Deficit = round(sum(Hdef > 0 )/Nloci, 4)) %>% 
  arrange(desc(Nloci))
kable(test_sum)

# Ensure m is treated as a factor for better grouping
test_sum$m <- as.factor(test_sum$m)

# Scatter plot: Nloci vs combinations of M and n
ggplot(test_sum, aes(x = interaction(M, n), y = Nloci)) +
  geom_point(size = 3) + # Use points instead of bars
  scale_y_continuous(
    limits = c(20000, 22500), 
    breaks = seq(0, 35000, by = 1500)
  ) +
  labs(
    x = "Combination of M and n",
    y = "Number of Loci (Nloci)",
    title = "Scatter Plot of Nloci Across Parameter Combinations"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1) # Tilt x-axis labels for readability
  )

# Bar plot: Nloci vs combinations of M and n, grouped by m
ggplot(test_sum, aes(x = interaction(M, n), y = Nloci)) +
  geom_bar(stat = "identity", fill = "gray") +
  scale_y_continuous(
    limits = c(0, 22500), 
    breaks = seq(0, 35000, by = 1500)
  ) +
  labs(
    x = "Combination of M and n",
    y = "Number of Loci (Nloci)",
    title = "Number of Loci for Different Parameter Combinations"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
