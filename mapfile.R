#denovo_map test with the catalog produced in the R80 test
popinfo <- "/home/clara.figueiredo/Projects/CZ1/popmap.wrk"
d <- "/home/clara.figueiredo/Projects/CZ1/sorted_by_population.log"

#produce map file por catalog
ssize <- 204 
MAFs <- c(0.01, 0.02, 0.05)

#chance of seeing at least one copy in the sample for MAFs 0.01, 0.02, 0.05. Poisson distribution it is used for Rare Events.
ppois(0, ssize*MAFs*2, lower.tail = FALSE) # ppois(0, ??, lower.tail = FALSE) ?? = mean and variance


catset <- 