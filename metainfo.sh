#!/bin/bash
#metainfo

radtag_dir=/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/ # output directory for demultiplexed files
bcode=/home/clara.figueiredo/Projects/CZ1/barcode/
rawdir=/home/clara.figueiredo/Projects/CZ1/Raw/
curdir=$(pwd)

stacks-dist-extract /home/clara.figueiredo/Projects/CZ1/dmpx_fastq/process_radtags.log total_raw_read_counts
stacks-dist-extract --pretty /home/clara.figueiredo/Projects/CZ1/dmpx_fastq/process_radtags.log per_barcode_raw_read_counts