#HAVING A SENSE of the distributions of reads per pop.  
library(tidyverse)
d <- read_tsv("sorted_by_reads.log")
names(d) <- c("id", "n_reads", "pop")
ggplot(d, aes(x = n_reads)) + geom_histogram(breaks = c(1e6, 2e6, 5e6,10e6, 2e7, 6e7)) +
   facet_wrap(vars(pop))

#The number of reads looks kind of homogeneous between populations