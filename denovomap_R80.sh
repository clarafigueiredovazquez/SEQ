#!/bin/bash
source /opt/miniconda3/etc/profile.d/conda.sh
conda activate stacks_env
# Define directories
fqdir=/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/fq_symlink/
mapfile=/home/clara.figueiredo/Projects/CZ1/test_Mmn.map
sum=Mmn_test_stats_additional_Mmn.txt


#we run the pipeline for XX samples with ca 11 million reads
#for M {2..6}, m{3 5}, n{$M, $M+2}
#then we combine all populations.sumstats.tsv adding the info about the M n m values

## RUN DENOVO MAP for PARAMETER OPTIMIZATION

for m in 3
    do
    for M in {3..7}
        do
        for n in $M $(( $M+2 ))
            do
            echo "Running with parameters: m=$m, M=$M, n=$n"

            odir=param_opt/M"$M"m"$m"n"$n"
            mkdir -p $odir

            denovo_map.pl --samples $fqdir --popmap $mapfile --out-path $odir --threads 35 -M $M -n $n --paired --min-samples-per-pop 0.8 -X "ustacks: -m $m" -X "populations: --hwe"
            #write sumstats to the summary file
            f="$odir"/populations.sumstats.tsv
            cat $f | awk -v M=$M -v n=$n -v m=$m 'BEGIN{FS=OFS="\t"} $0 !~ /^#/ {print M, n, m, $1, $3, $8, $10, $12, $17, $20}' >> $sum 
            done
        done
    done

echo "Parameter optimization completed"

#NOTES#
#The subset of samples include individuals from both taxa (gallaica and bernardezi)