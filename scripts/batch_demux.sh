#!/bin/bash
set -e 
set -o pipefail

# Split a directory containing raw .fastq files into subdirectories
# each containing a prespecified number of files
# Porechop will be run on each sequentially to prevent memory issues
# due to loading the entire concatenated fastq.gz file

#### INPUT FILES ####

DIR=$1 # project directory
SAMPLE_SHEET=$2 # sample sheet
NUM_CORES=$3 # number of processors available

#### VALUES THAT CAN BE CONFIGURED ####

FASTQ="$DIR/basecalled" # assumed path to raw fastq files
NUM_FILES=20 # number of fastq files per subdirectory


#### BEGIN DEMUX SCRIPT ####

#### SPLIT FILES INTO SUBDIRECTORIES ####

mkdir $FASTQ/bins
cd $FASTQ/bins/
declare -a bins

COUNTER=0
for f in $FASTQ/*.fastq; do
	d=bin_$(printf %03d $(($COUNTER/$NUM_FILES+1))) # determine the name of the directory
	bins+=( $d ) # add directory name to array to save for later
	mkdir -p $d # make the new directory
	mv $f $d # move the current fastq file to the directory
	COUNTER=$((COUNTER + 1)) # increase the counter
done

echo "moved all the files, beginning demux"


#### RUN PORECHOP ON EACH SUBDIRECTORY ####

uniq=($(printf "%s\n" "${bins[@]}" | sort -u | tr '\n' ' ')) # get unique bins
declare -a demux_dirs

for d in "${uniq[@]}";
do
	echo "$d demux starting"
	porechop --format fastq.gz -b $DIR/demux/$d -i $FASTQ/bins/$d -t $NUM_CORES
	demux_dirs+=( $DIR/demux/$d )
	mv $FASTQ/bins/$d/* $FASTQ/ # add code to move files out of bins directory
	rmdir $FASTQ/bins/$d
done

#### CONCATENATE RESULTS FROM ALL BINS ####

while read line; do
	b=$(echo $line | awk '{print $2}')
	echo "BARCODE $b"
	declare -a fq	
	for d in "${demux_dirs[@]}"; do fq+=( $d/$b.fastq.gz ); done
	cat ${fq[@]} > $DIR/demux/$b.fastq.gz	
	unset fq
done < $SAMPLE_SHEET

echo "demux portion complete, now rename files"

# rename output files according to sample sheet

while read line; do
	SAMPLENAME=$(echo $line | awk '{print $1}').fastq.gz
	BARCODE=$(echo $line | awk '{print $2}').fastq.gz
	mv $DIR/demux/$BARCODE $DIR/demux/$SAMPLENAME
done < $SAMPLE_SHEET

echo "batch demux completed successfully"
