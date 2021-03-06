#! /bin/bash
set -e 
set -o pipefail

#Use nanopolish to index reads based on raw signal data,
#then use minimap2 to align reads to a pre-specified reference,
#and finally call variants based on this alignment

#### INPUT FILES ####

# get sample name and directories from command line
NAME=$1 # sample name
DIR=$2 # path to project directory
READS=$3 # path to raw .fast5 files
NUM_CORES=$4 # number of cores available

#### CHECK DIRECTORIES ####

# fist check that the provided working directory is a real directory
# with reads for the desired sample in the demux directory
if [ ! -d $DIR ]; then
	echo "ERROR: invalid directory provided"
	exit 1
fi

if [ ! -f $DIR/demux/$NAME.fastq.gz ]; then
	echo "ERROR: reads for sample $NAME not in $DIR/demux/"
fi

echo "output file for $NAME"

DIR=${DIR%/} # remove trailing slash from directory name if necessary

# create necessary directories
# if they do not exist already
if [ ! -d $DIR/nanopolish ]; then
	mkdir $DIR/nanopolish
fi

if [ ! -d $DIR/tmp ]; then
	mkdir $DIR/tmp
fi

if [ ! -d $DIR/genomes ]; then
	mkdir $DIR/genomes
fi

#### VALUES TO CHANGE PRIOR TO RUN ####

READ_SUMMARY=$DIR/basecalled/sequencing_summary.txt # path to sequencing summary file generated by guppy

REF=$DIR/ref_genomes/reference.fasta # path to reference genome
CONTIG_NAME="MN908947.3"
CONTIG_LEN=29903

SNP_SUPPORT=0.75
REQ_DEPTH=20

#### BEGIN NANOPOLISH PIPELINE ####

date
echo "running nanopolish index"

#index reads individually for each sample
if [ ! -f $DIR/demux/$NAME.fastq.gz.index ]; then
	nanopolish index -d $READS -s $READ_SUMMARY $DIR/demux/$NAME.fastq.gz
fi

date
echo "running minimap2"

# map reads to reference
if [ ! -f $DIR/nanopolish/$NAME.aln.ref.sorted.bam ]; then
	minimap2 -ax map-ont -t $NUM_CORES $REF $DIR/demux/$NAME.fastq.gz | \
		samtools sort -@ $NUM_CORES -o $DIR/nanopolish/$NAME.aln.ref.sorted.bam \
		-T $DIR/nanopolish/tmp/$NAME.reads.tmp
	samtools index $DIR/nanopolish/$NAME.aln.ref.sorted.bam
fi

echo "number of reads in sample $NAME:"
samtools view -c $DIR/nanopolish/$NAME.aln.ref.sorted.bam

echo "number of mapped reads in sample $NAME:"
samtools view -c -F 4 $DIR/nanopolish/$NAME.aln.ref.sorted.bam

date
echo "calling variants with nanopolish"

# set the desired header text
echo "##contig=<ID=$CONTIG_NAME,length=$CONTIG_LEN>" > $DIR/nanopolish/headertext.txt

# call variants with nanopolish
if [ ! -f $DIR/nanopolish/$NAME.nanopolish.vcf ]; then
	nanopolish variants -o $DIR/nanopolish/$NAME.nanopolish.vcf \
		-p 1 \
		-r $DIR/demux/$NAME.fastq.gz \
		-b $DIR/nanopolish/$NAME.aln.ref.sorted.bam \
		-g $REF \
		-t $NUM_CORES

	# update the header for this VCF file
	bcftools annotate -h $DIR/nanopolish/headertext.txt -o $DIR/nanopolish/$NAME.nanopolish.vcf \
	--no-version $DIR/nanopolish/$NAME.nanopolish.vcf
fi

date
echo "variants called successfully"

# filter VCF on hard-coded SNP support and read depth

if [ ! -f $DIR/nanopolish/$NAME.nanopolish.filt.vcf ]; then
	#filter vcf on hard-coded support and read depth
	bcftools filter --no-version -i "INFO/SupportFraction>$SNP_SUPPORT" $DIR/nanopolish/$NAME.nanopolish.vcf | \
		bcftools filter --no-version -i "INFO/TotalReads>$REQ_DEPTH" -o $DIR/nanopolish/$NAME.nanopolish.filt.vcf
fi

#compress and index files for optional additional vcf manipulation
if [ ! -f $DIR/nanopolish/$NAME.nanopolish.filt.rename.vcf.gz ]; then
	
	bcftools view --no-version -O z -o $DIR/nanopolish/$NAME.nanopolish.filt.vcf.gz $DIR/nanopolish/$NAME.nanopolish.filt.vcf
	echo "sample $NAME" > $DIR/nanopolish/reheader-vcf.txt
	bcftools reheader -s $DIR/nanopolish/reheader-vcf.txt -o $DIR/nanopolish/$NAME.nanopolish.filt.rename.vcf.gz \
		$DIR/nanopolish/$NAME.nanopolish.filt.vcf.gz
	bcftools index --threads $NUM_CORES $DIR/nanopolish/$NAME.nanopolish.filt.rename.vcf.gz
fi

# calculate depth at each position
# needed to make consensus genome
samtools depth -a -m 10000 $DIR/nanopolish/$NAME.aln.ref.sorted.bam > $DIR/nanopolish/$NAME.ref.depth.txt

echo "nanopolish script completed successfully"