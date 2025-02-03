#Plot reads per sample#
# Load necessary library
library(ggplot2)
library(dplyr)


# Load the data
file_path <- "C:/Users/clara/OneDrive/PhD/CZ1/Data/SEQ/updated_demultiplexing_summary.log"
data <- read.table(file_path, header = TRUE, sep = "\t", stringsAsFactors = FALSE)

# Calculate the average and standard deviation of Retained Reads for all samples
avg_reads <- mean(data$`Retained.Reads`)
sd_reads <- sd(data$`Retained.Reads`)

# Print the results
cat("Average number of Retained Reads:", avg_reads, "\n")
cat("Standard deviation of Retained Reads:", sd_reads, "\n")

# Filter top 2 samples per population
top_two <- data %>%
  group_by(POPULATION) %>%
  slice_max(order_by = `Retained.Reads`, n = 2)

# Filter top 2 samples per population
top_two <- data %>%
  group_by(POPULATION) %>%
  slice_max(order_by = `Retained.Reads`, n = 2)

# Create the scatterplot
ggplot(top_two, aes(x = SAMPLE, y = `Retained.Reads`, color = POPULATION)) +
  geom_point(size = 3) +
  labs(
    title = "Top 2 Samples by Retained Reads per Population",
    x = "Sample",
    y = "Number of Retained Reads"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "bottom"
  )

# Save the plot
ggsave("scatter_top_two_samples_per_population.png", width = 12, height = 6)