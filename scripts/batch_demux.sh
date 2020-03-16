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
NUM_FILES=50 # number of fastq files per subdirectory


#### BEGIN DEMUX SCRIPT ####

date

#### SPLIT FILES INTO SUBDIRECTORIES ####

# if fastq files have not yet been sorted into bins
if [ ! -d $FASTQ/bins/ ]
	then
		
		# make a new subdirectory
		mkdir $FASTQ/bins
		cd $FASTQ/bins/

		# loop through fastq files and sort them into appropriate bins
		COUNTER=0
		for f in $FASTQ/*.fastq; do
			d=bin_$(printf %03d $(($COUNTER/$NUM_FILES+1))) # determine the name of the directory
			mkdir -p $d # make the new directory
			mv $f $d # move the current fastq file to the directory
			COUNTER=$((COUNTER + 1)) # increase the counter
		done

		echo "moved all the files, beginning demux"

	# if the fastq files have already been sorted (this is a restart of the demux script)
	else
		echo "resuming demux"
fi

#### RUN PORECHOP ON EACH SUBDIRECTORY ####

# bin directories are removed after their demux is completed
# so we cant just loop through the remaining directories

for d in $FASTQ/bins/*/
do
	b=${d::-1}
	b=${b##*/}
	echo "$b demux starting"
	porechop --format fastq.gz -b $DIR/demux/$b -i $FASTQ/bins/$b -t $NUM_CORES
	mv $FASTQ/bins/$b/* $FASTQ/ # add code to move files out of bins directory
	rmdir $FASTQ/bins/$b
done

echo "demux complete, concatenating files"

#### CONCATENATE RESULTS FROM ALL BINS ####

while read line; do
	b=$(echo $line | awk '{print $2}')
	echo "BARCODE $b"
	declare -a fq	
	for d in $DIR/demux/*/; do fq+=( $d$b.fastq.gz ); done
	cat ${fq[@]} > $DIR/demux/$b.fastq.gz	
	unset fq
done < $SAMPLE_SHEET

echo "concatenating files complete, renaming files"

# rename output files according to sample sheet

while read line; do
	SAMPLENAME=$(echo $line | awk '{print $1}').fastq.gz
	BARCODE=$(echo $line | awk '{print $2}').fastq.gz
	mv $DIR/demux/$BARCODE $DIR/demux/$SAMPLENAME
done < $SAMPLE_SHEET

date
echo "batch demux completed successfully"