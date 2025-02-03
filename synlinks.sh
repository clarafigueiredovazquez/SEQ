#!/bin/bash
#create symlinks to all fq.gz files

radtag_dir=/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/
symlinks_dir=/home/clara.figueiredo/Projects/CZ1/dmpx_fastq/fq_symlink/
mkdir -p "$symlinks_dir"

#CZ1  
find "$radtag_dir" -type f -name "*.fq.gz" -exec ln -s {} "$symlinks_dir" \;

# Output message for debugging
echo "Symlinks for .fq.gz files created in $symlinks_dir"